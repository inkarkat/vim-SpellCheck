" SpellCheck.vim: Check for spelling errors.
"
" DEPENDENCIES:
"   - ingo/msg.vim autoload script
"   - ingo/plugin/setting.vim autoload script
"
" Copyright: (C) 2011-2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
let s:save_cpo = &cpo
set cpo&vim

function! SpellCheck#ParseArguments( arguments )
    let l:types = []
    let l:arguments = a:arguments
    while l:arguments =~# '^\a\+\%(\s\|$\)'
	let [l:first, l:rest] = matchlist(l:arguments, '^\(\a\+\)\s*\(.*\)$')[1:2]
	if index(g:SpellCheck_ErrorTypes, l:first) != -1
	    call add(l:types, l:first)
	    let l:arguments = l:rest
	else
	    break
	endif
    endwhile

    return [
    \   ingo#collections#ToDict(empty(l:types) ?
    \       ingo#plugin#setting#GetBufferLocal('SpellCheck_ConsideredErrorTypes') :
    \       l:types
    \   ),
    \   (empty(l:arguments) ?
    \       ingo#plugin#setting#GetBufferLocal('SpellCheck_Predicates') :
    \       l:arguments
    \   )
    \]
endfunction
function! SpellCheck#ApplyPredicates( predicates )
    return empty(a:predicates) || eval(a:predicates)
endfunction

function! SpellCheck#AutoEnableSpell()
    setlocal spell
    if empty(&l:spelllang)
	throw 'No spell language defined; use :setl spl=... to enable spell checking'
    endif
endfunction

function! SpellCheck#SpellAddWrapper( count, command )
    call SpellCheck#AutoEnableSpell()
    try
	execute 'normal!' a:count . a:command
	return 1
    catch /^Vim\%((\a\+)\)\=:/
	call ingo#msg#VimExceptionMsg()
	return 0
    endtry
endfunction

function! SpellCheck#CheckEnabledSpelling()
    if ! &l:spell
	if ! empty(g:SpellCheck_OnNospell)
	    " Allow hook to enable spelling using some sort of logic.
	    try
		call call(g:SpellCheck_OnNospell, [])
	    catch
		call ingo#msg#VimExceptionMsg()
		return 0
	    endtry
	endif
    endif
    if ! &l:spell || empty(&l:spelllang)
	call ingo#msg#ErrorMsg('E756: Spell checking is not enabled')
	return 0
    endif

    return 1
endfunction

function! s:GotoNextSpellError()
    let l:save_wrapscan = &wrapscan
    set nowrapscan
	silent! keepjumps normal! ]s
    let &wrapscan = l:save_wrapscan
endfunction
function! s:GotoFirstMisspelling()
    let l:save_wrapscan = &wrapscan
    set nowrapscan
	silent! normal! gg0]s[s
    let &wrapscan = l:save_wrapscan
    normal! zv
endfunction
function! SpellCheck#CheckErrors( firstLine, lastLine, isNoJump, arguments )
    if ! SpellCheck#CheckEnabledSpelling()
	return 2
    endif

    let [l:types, l:predicates] = SpellCheck#ParseArguments(a:arguments)
    let l:save_view = winsaveview()
    try
	let l:isError = 0
	let l:isFirst = 1
	call cursor(a:firstLine, 1)
	while 1
	    let l:currentPos = getpos('.')
	    call s:GotoNextSpellError()

	    if line('.') < a:firstLine || line('.') > a:lastLine
		" The next spell error lies outside the passed range.
	    elseif getpos('.') != l:currentPos
		let l:isError = 1
	    elseif l:isFirst
		" Either there are no spelling errors at all, or we're on the sole
		" spelling error in the buffer.
		let l:isError = ! empty(spellbadword()[0])
	    endif

	    if l:isError
		if empty(l:types)
		    if ! SpellCheck#ApplyPredicates(l:predicates)
			" The predicates signal to ignore this error, keep searching.
			let l:isError = 0
			let l:isFirst = 0
			continue
		    endif
		else
		    let [l:spellBadWord, l:errorType] = spellbadword()
		    if ! has_key(l:types, l:errorType) || ! SpellCheck#ApplyPredicates(l:predicates)
			" This is an ignored type of error, or it is ignored by
			" predicates; keep searching.
			let l:isError = 0
			let l:isFirst = 0
			continue
		    endif
		endif
	    endif

	    break
	endwhile
	let l:errorPos = getpos('.')
    catch /^Vim\%((\a\+)\)\=:/
	call ingo#msg#VimExceptionMsg()
	return 1
    finally
	call winrestview(l:save_view)
    endtry

    if l:isError
	if ! a:isNoJump
	    normal! m'
	    call cursor(l:errorPos[1:2])
	endif

	call ingo#msg#ErrorMsg('There are spelling errors')
    else
	call SpellCheck#NoErrorsFoundMessage(l:types, l:predicates)
    endif

    return l:isError
endfunction

function! SpellCheck#NoErrorsFoundMessage( types, predicates )
    call ingo#msg#StatusMsg(printf('No %sspell errors found%s',
    \   (empty(a:types) ? '' : join(sort(keys(a:types)), ' or ') . ' '),
    \   (empty(a:predicates) ? '' : ' where ' . a:predicates)
    \))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

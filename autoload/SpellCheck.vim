" SpellCheck.vim: Check for spelling errors.
"
" DEPENDENCIES:
"   - ingo/msg.vim autoload script
"
" Copyright: (C) 2011-2015 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.40.006	09-Feb-2015	Make SpellCheck#CheckErrors() take an additional
"				a:types argument to support filtering for
"				certain spell error types. Add loop and iterate
"				until an corresponding spell error type is
"				encountered or an exit condition is met.
"				Always position the cursor at the beginning of
"				the checked range. This avoids the workaround in
"				s:GotoNextSpellError() and lets us :set
"				nowrapscan, to avoid endless iteration.
"				Go to the first misspelling in the passed range
"				(if any) instead of the first overall. I think
"				this is more DWIM.
"				Extract SpellCheck#NoErrorsFoundMessage() and
"				create SpellCheck#GetTypes() for reuse.
"   1.21.005	14-Jun-2013	Use ingo/msg.vim.
"   1.20.004	08-May-2012	ENH: Allow [range] for :BDeleteUnlessSpellError
"				and other :...UnlessSpellError commands, too.
"   1.10.003	30-Apr-2012	Add SpellCheck#SpellAddWrapper() function as
"				default for new g:SpellCheck_OnSpellAdd hook.
"   1.00.002	06-Dec-2011	Publish.
"	002	03-Dec-2011	New default behavior on &nospell is to just turn
"				on &spell, and cause an error when no &spelllang
"				has been set yet.
"	001	02-Dec-2011	file creation
let s:save_cpo = &cpo
set cpo&vim

function! SpellCheck#GetTypes( types )
    return ingo#collections#ToDict(empty(a:types) ?
    \   g:SpellCheck_ConsideredErrorTypes :
    \   split(a:types)
    \)
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
	silent! normal! ]s
    let &wrapscan = l:save_wrapscan
endfunction
function! s:GotoFirstMisspelling()
    let l:save_wrapscan = &wrapscan
    set nowrapscan
	silent! normal! gg0]s[s
    let &wrapscan = l:save_wrapscan
    normal! zv
endfunction
function! SpellCheck#CheckErrors( firstLine, lastLine, isNoJump, types )
    if ! SpellCheck#CheckEnabledSpelling()
	return 2
    endif

    let l:types = SpellCheck#GetTypes(a:types)
    let l:save_view = winsaveview()
	let l:isError = 0
	call cursor(a:firstLine, 1)
	while 1
	    let l:currentPos = getpos('.')
	    call s:GotoNextSpellError()

	    if line('.') < a:firstLine || line('.') > a:lastLine
		" The next spell error lies outside the passed range.
	    elseif getpos('.') != l:currentPos
		let l:isError = 1
	    else
		" Either there are no spelling errors at all, or we're on the sole
		" spelling error in the buffer.
		let l:isError = ! empty(spellbadword()[0])
	    endif

	    if l:isError && ! empty(l:types)
		let [l:spellBadWord, l:errorType] = spellbadword()
		if ! has_key(l:types, l:errorType)
		    " This is an ignored type of error, keep searching.
		    continue
		endif
	    endif

	    break
	endwhile
	let l:errorPos = getpos('.')
    call winrestview(l:save_view)

    if l:isError
	if ! a:isNoJump
	    normal! m'
	    call cursor(l:errorPos[1:2])
	endif

	call ingo#msg#ErrorMsg('There are spelling errors')
    else
	call SpellCheck#NoErrorsFoundMessage(l:types)
    endif

    return l:isError
endfunction

function! SpellCheck#NoErrorsFoundMessage( types )
    call ingo#msg#StatusMsg(printf('No %sspell errors found', (empty(a:types) ? '' : join(sort(keys(a:types)), ' or ') . ' ')))
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

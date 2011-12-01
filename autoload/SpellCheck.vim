" SpellCheck.vim: Check for spelling errors. 
"
" DEPENDENCIES:
"
" Copyright: (C) 2011 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	02-Dec-2011	file creation

function! SpellCheck#CheckEnabledSpelling()
    if ! &l:spell
	if ! empty(g:SpellCheck_OnSpellOff)
	    " Allow hook to enable spelling using some sort of logic. 
	    call call(g:SpellCheck_OnSpellOff, [])
	endif
    endif
    if ! &l:spell || empty(&l:spelllang)
	let v:errmsg = 'E756: Spell checking is not enabled'
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None

	return 0
    endif

    return 1
endfunction

function! s:GotoNextSpellError()
    let l:save_wrapscan = &wrapscan
    set wrapscan
	silent! normal! ]s
    let &wrapscan = l:save_wrapscan
endfunction
function! SpellCheck#CheckErrors()
    if ! SpellCheck#CheckEnabledSpelling()
	return 2
    endif

    let l:save_view = winsaveview()
	let l:isError = 0
	let l:currentPos = getpos('.')

	call s:GotoNextSpellError()

	if getpos('.') != l:currentPos
	    let l:isError = 1
	else
	    " Either there are no spelling errors at all, or we're on the sole
	    " spelling error in the buffer. 
	    let l:isError = ! empty(spellbadword()[0])
	endif
    call winrestview(l:save_view)

    if l:isError
	let v:errmsg = 'There are spelling errors'
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None
    else
	echomsg 'No spell errors found'
    endif

    return l:isError
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

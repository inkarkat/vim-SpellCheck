" SpellCheck.vim: Check for spelling errors.
"
" DEPENDENCIES:
"   - ingo/msg.vim autoload script
"
" Copyright: (C) 2011-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
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
    set wrapscan
	" XXX: Vim 7.3 does not move to the sole spell error when the cursor is
	" after the spell error in the same line. Work around this by trying the
	" other direction, too, but ensure to keep within a passed range by
	" moving back forward again.
	"silent! normal! ]s
	silent! normal! ]s[s]s
    let &wrapscan = l:save_wrapscan
endfunction
function! s:GotoFirstMisspelling()
    let l:save_wrapscan = &wrapscan
    set nowrapscan
	silent! normal! gg0]s[s
    let &wrapscan = l:save_wrapscan
    normal! zv
endfunction
function! SpellCheck#CheckErrors( firstLine, lastLine, isNoJump )
    if ! SpellCheck#CheckEnabledSpelling()
	return 2
    endif

    let l:save_view = winsaveview()
	let l:isError = 0
	if a:firstLine > 1 || a:lastLine < line('$')
	    " When not the entire buffer is covered, put the cursor at the
	    " beginning of the range, so that a valid spell error can be
	    " discovered with a single jump to the next error.
	    call cursor(a:firstLine, 1)
	endif
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
    call winrestview(l:save_view)

    if l:isError
	if ! a:isNoJump
	    call s:GotoFirstMisspelling()
	endif

	call ingo#msg#ErrorMsg('There are spelling errors')
    else
	call ingo#msg#StatusMsg('No spell errors found')
    endif

    return l:isError
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

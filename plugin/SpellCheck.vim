" ingospelllist.vim: summary
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

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_ingospelllist') || (v:version < 700)
    finish
endif
let g:loaded_ingospelllist = 1

function! s:GotoNextLine()
    if line('.') < line('$')
	call cursor(line('.') + 1, 1)
	return 1
    else
	return 0
    endif
endfunction
function! s:RetrieveSpellErrors()
    let l:spellErrorInfo = {}
    let l:spellErrorList = []
    call cursor(1,1)

    while 1
	let [l:spellBadWord, l:errorType] = spellbadword()
	if empty(l:spellBadWord)
	    if s:GotoNextLine()
		continue
	    else
		break
	    endif
	endif

	if has_key(l:spellErrorInfo, l:spellBadWord)
	    let l:spellErrorInfo[l:spellBadWord].count += 1
	else
	    let l:spellErrorInfo[l:spellBadWord] = {'type': l:errorType, 'lnum': line('.'), 'col': col('.'), 'count': 1}
	    call add(l:spellErrorList, l:spellBadWord)
	endif

	let l:colAfterBadWord = col('.') + len(l:spellBadWord)
	if l:colAfterBadWord < col('$')
	    call cursor(line('.'), l:colAfterBadWord)
	elseif ! s:GotoNextLine()
	    break
	endif
    endwhile

    return [l:spellErrorList, l:spellErrorInfo]
endfunction

function! s:List()
    if ! &l:spell
	call ingospell#ToggleSpelling(0)
    endif
    if ! &l:spell || empty(&l:spelllang)
	let v:errmsg = 'E756: Spell checking is not enabled'
	echohl ErrorMsg
	echomsg v:errmsg
	echohl None

	return
    endif

    let l:save_view = winsaveview()
    let [l:spellErrorList, l:spellErrorInfo] = s:RetrieveSpellErrors()
    echomsg string(l:spellErrorList)
    call winrestview(l:save_view)
endfunction
command! -bar SpellList call <SID>List()

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

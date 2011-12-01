" SpellCheck/quickfix.vim: Show all spelling errors as a quickfix list. 
"
" DEPENDENCIES:
"   - SpellCheck.vim autoload script. 
"
" Copyright: (C) 2011 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	02-Dec-2011	file creation

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
function! s:ToQfEntry( error, bufnr, spellErrorInfo )
    let l:entry = a:spellErrorInfo
    let l:entry.bufnr = a:bufnr
    let l:entry.text = a:error . (l:entry.count > 1 ? ' (' . l:entry.count . ')' : '')
    let l:entry.type = (l:entry.type ==# 'bad' || l:entry.type ==# 'caps' ? '' : 'W')
    return l:entry
endfunction
function! s:FillQuickfixList( bufnr, spellErrorList, spellErrorInfo, isNoJump, isUseLocationList )
    let l:qflist = map(a:spellErrorList, 's:ToQfEntry(v:val, a:bufnr, a:spellErrorInfo[v:val])')

    silent execute 'doautocmd QuickFixCmdPre' (a:isUseLocationList ? 'lspell' : 'spell') | " Allow hooking into the quickfix update. 

    if a:isUseLocationList
	let l:list = 'l'
	call setloclist(0, l:qflist, ' ')
    else
	let l:list = 'c'
	call setqflist(l:qflist, ' ')
    endif

    if len(a:spellErrorList) > 0
	if ! a:isNoJump
	    execute l:list . 'first'
	endif
    endif

    silent execute 'doautocmd QuickFixCmdPost' (a:isUseLocationList ? 'lspell' : 'spell') | " Allow hooking into the quickfix update. 
endfunction

function! SpellCheck#quickfix#List( isNoJump, isUseLocationList )
    if ! SpellCheck#CheckEnabledSpelling()
	return 2
    endif

    let l:save_view = winsaveview()
	let [l:spellErrorList, l:spellErrorInfo] = s:RetrieveSpellErrors()
    call winrestview(l:save_view)

    call s:FillQuickfixList(bufnr(''), l:spellErrorList, l:spellErrorInfo, a:isNoJump, a:isUseLocationList)
    if len(l:spellErrorList) == 0
	echomsg 'No spell errors found'
    endif

    return (len(l:spellErrorList) > 0)
endfunction

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

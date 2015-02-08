" SpellCheck/quickfix.vim: Show all spelling errors as a quickfix list.
"
" DEPENDENCIES:
"   - SpellCheck.vim autoload script.
"
" Copyright: (C) 2011-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.30.006	22-Jul-2014	ENH: Gather (if configured) error context(s) and
"				append to the quickfix entry.
"   1.12.005	01-May-2012	ENH: Allow [range] for :SpellCheck command.
"   1.01.002	06-Dec-2011	ENH: Allow accumulating spelling errors from
"				multiple buffers (e.g. via :argdo SpellCheck).
"   1.00.001	06-Dec-2011	Publish.
"	001	02-Dec-2011	file creation
let s:save_cpo = &cpo
set cpo&vim

function! s:GotoNextLine( lastLine )
    if line('.') < a:lastLine
	call cursor(line('.') + 1, 1)
	return 1
    else
	return 0
    endif
endfunction
function! s:GetErrorContext( lnum, col )
    return matchstr(getline(a:lnum), printf(g:SpellCheck_ErrorContextPattern, '\%' . a:col . 'c'))
endfunction
function! s:RetrieveSpellErrors( firstLine, lastLine )
    let l:spellErrorInfo = {}
    let l:spellErrorList = []
    call cursor(a:firstLine, 1)

    while 1
	let [l:spellBadWord, l:errorType] = spellbadword()
	if empty(l:spellBadWord)
	    if s:GotoNextLine(a:lastLine)
		continue
	    else
		break
	    endif
	endif

	let [l:lnum, l:col] = getpos('.')[1:2]
	if has_key(l:spellErrorInfo, l:spellBadWord)
	    let l:entry = l:spellErrorInfo[l:spellBadWord]
	    let l:entry.count += 1
	    if len(l:entry.context) < g:SpellCheck_ErrorContextNum
		call ingo#collections#unique#AddNew(l:entry.context, s:GetErrorContext(l:lnum, l:col))
	    endif
	else
	    let l:spellErrorInfo[l:spellBadWord] = {
	    \   'type': l:errorType,
	    \   'lnum': l:lnum,
	    \   'col': l:col,
	    \   'count': 1,
	    \   'context': (g:SpellCheck_ErrorContextNum > 0 ? [s:GetErrorContext(l:lnum, l:col)] : [])
	    \}
	    call add(l:spellErrorList, l:spellBadWord)
	endif

	let l:colAfterBadWord = col('.') + len(l:spellBadWord)
	if l:colAfterBadWord < col('$')
	    call cursor(line('.'), l:colAfterBadWord)
	elseif ! s:GotoNextLine(a:lastLine)
	    break
	endif
    endwhile

    return [l:spellErrorList, l:spellErrorInfo]
endfunction
function! s:ToQfEntry( error, bufnr, spellErrorInfo )
    let l:entry = a:spellErrorInfo
    let l:entry.bufnr = a:bufnr
    let l:entry.text = a:error .
    \   (l:entry.count > 1 ? ' (' . l:entry.count . ')' : '') .
    \   (empty(l:entry.context) ? '' : "\t\t" . join(l:entry.context, ', '))
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

	let l:errorsFromOtherBuffers = filter(getqflist(), 'v:val.bufnr != a:bufnr')
	if empty(l:errorsFromOtherBuffers)
	    " We haven't accumulated spelling errors from multiple buffers, just
	    " replace the entire quickfix list.
	    call setqflist(l:qflist, ' ')
	else
	    " To allow accumulating spelling errors from multiple buffers (e.g.
	    " via :argdo SpellCheck), just remove the previous errors for the
	    " current buffer, and append the new list.
	    call setqflist(l:errorsFromOtherBuffers + l:qflist, 'r')

	    " Jump to the first updated spelling error of the current buffer.
	    let l:list = (len(l:errorsFromOtherBuffers) + 1) . 'c'
	endif
    endif

    if len(a:spellErrorList) > 0
	if ! a:isNoJump
	    execute l:list . 'first'
	    normal! zv
	endif
    endif

    silent execute 'doautocmd QuickFixCmdPost' (a:isUseLocationList ? 'lspell' : 'spell') | " Allow hooking into the quickfix update.
endfunction

function! SpellCheck#quickfix#List( firstLine, lastLine, isNoJump, isUseLocationList )
    if ! SpellCheck#CheckEnabledSpelling()
	return 2
    endif

    let l:save_view = winsaveview()
	let [l:spellErrorList, l:spellErrorInfo] = s:RetrieveSpellErrors(a:firstLine, a:lastLine)
    call winrestview(l:save_view)

    call s:FillQuickfixList(bufnr(''), l:spellErrorList, l:spellErrorInfo, a:isNoJump, a:isUseLocationList)
    if len(l:spellErrorList) == 0
	echomsg 'No spell errors found'
    endif

    return (len(l:spellErrorList) > 0)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

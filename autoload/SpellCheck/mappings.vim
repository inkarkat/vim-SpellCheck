" SpellCheck/mappings.vim: Special quickfix window mappings.
"
" DEPENDENCIES:
"   - SpellCheck.vim autoload script
"
" Copyright: (C) 2012 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.10.001	29-Apr-2012	file creation

function! SpellCheck#mappings#SpellSuggestWrapper( ... )
    let l:addendum = ''
    let l:followUpCommands = copy(a:000)

    if ! &l:spell
	if SpellCheck#CheckEnabledSpelling()
	    call insert(l:followUpCommands, 'setlocal nospell', 0)
	else
	    setlocal nospell    " This might have been set by SpellCheck#CheckEnabledSpelling().
	    return
	endif
    endif

    if ! empty(l:followUpCommands)
	" If no [count] is given, the z= command queries the spell suggestion.
	" Unfortunately, the querying is disturbed by any following typeahead,
	" even when submitted via feedkeys(). To work around this, we set up a
	" temporary autocommand that fires once at the next possible point in
	" time, then deletes itself.
	if v:count
	    " No querying, so we can simply append the command to undo the
	    " temporary enabling of spelling.
	    let l:addendum = ':' . join(l:followUpCommands, '|') . "\<CR>"
	else
	    " Turn off 'spell' at the next possible event:
	    " BufLeave: Before another buffer is loaded in the current window.
	    " WinLeave: Before the window is left.
	    " InsertEnter: Editing is started (or resumed from an insert mode
	    "              <C-O>{cmd}).
	    " CursorHold: Nothing happened after the {cmd}.
	    " CursorMoved: The user jumped around in the current buffer.
	    augroup SpellSuggestOff
		autocmd!
		execute 'autocmd BufLeave,WinLeave,InsertEnter,CursorHold,CursorMoved <buffer> execute "autocmd! SpellSuggestOff" | ' . join(l:followUpCommands, '|')
	    augroup END
	endif
    endif

    return 'z=' . l:addendum
endfunction
function! SpellCheck#mappings#SpellRepeat()
    try
	" Always print the number of repeated spell corrections, even if there
	" is only one.
	let l:save_report = &report
	set report=0

	spellrepall
    catch /^Vim\%((\a\+)\)\=:E75[23]/  " E752: No previous spell replacement; E753: Not found: ...
	" Silently ignore the fact that the misspelled word didn't occur
	" elsewhere.
    finally
	let &report = l:save_report
    endtry
endfunction


function! s:SetCount()
    let s:count = (v:count ? v:count : '')
endfunction
function! s:GetCount()
    return s:count
endfunction
function! SpellCheck#mappings#MakeMappings()
    for l:command in ['zg', 'zG', 'zw', 'zW', 'zug', 'zuG', 'zuw', 'zuW']
	execute printf('nnoremap <silent> <buffer> %s :<C-u>execute "normal! \<lt>CR>"<Bar>call call(g:SpellCheck_OnSpellAdd, [(v:count ? v:count : ""), %s])<Bar>wincmd p<CR>', l:command, string(l:command))
    endfor

    nnoremap <silent> <expr> <SID>(SpellSuggestWrapper) <SID>GetCount() . SpellCheck#mappings#SpellSuggestWrapper('call SpellCheck#mappings#SpellRepeat()', 'wincmd p')
    nnoremap <silent> <script> <buffer> z= :<C-u>call <SID>SetCount()<CR><CR><SID>(SpellSuggestWrapper)
endfunction


" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

" SpellCheck.vim: Work with spelling errors. 
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher. 
"   - SpellCheck/quickfix.vim autoload script. 
"
" Copyright: (C) 2011 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'. 
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS 
"	001	02-Dec-2011	file creation

" Avoid installing twice or when in unsupported Vim version. 
if exists('g:loaded_SpellCheck') || (v:version < 700)
    finish
endif
let g:loaded_SpellCheck = 1

"- configuration ---------------------------------------------------------------

if ! exists('g:SpellCheck_OnSpellOff')
    let g:SpellCheck_OnSpellOff = ''
endif


"- commands --------------------------------------------------------------------

":SpellCheck[!]		Show all spelling errors as a quickfix list. 
"			For multiple occurrences of the same error, the first
"			location and the number of occurrences is shown. 
"			If [!] is not given the first error is jumped to. 
":SpellLCheck[!]
"			Same as ":SpellCheck", except the location list for the
"			current window is used instead of the quickfix list. 
command! -bar -bang SpellCheck  call SpellCheck#quickfix#List(<bang>0, 0)
command! -bar -bang SpellLCheck call SpellCheck#quickfix#List(<bang>0, 1)

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

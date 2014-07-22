" SpellCheck.vim: Work with spelling errors.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - SpellCheck/quickfix.vim autoload script.
"
" Copyright: (C) 2011-2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"   1.30.008	22-Jul-2014	Add configuration for error context.
"   1.21.007	23-Sep-2013	Add :NextUnlessSpellError and :NextOrSpellCheck
"				auxiliary commands.
"				Allow to pass optional [++opt] [file] arguments
"				to the :Write... commands.
"   1.20.006	08-May-2012	FIX: Line range is not defined and passed for
"				:BDeleteOrSpellCheck and other :...OrSpellCheck
"				commands, resulting in a script error.
"				ENH: Allow [range] for :BDeleteUnlessSpellError
"				and other :...UnlessSpellError commands, too.
"   1.12.005	01-May-2012	ENH: Allow [range] for :SpellCheck command.
"   1.10.004	30-Apr-2012	Add g:SpellCheck_OnSpellAdd hook.
"   1.00.003	06-Dec-2011	FIX: Missing :quit in :XitOrSpellCheck.
"	002	03-Dec-2011	Rename configvar to g:SpellCheck_OnNospell.
"	001	02-Dec-2011	file creation

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_SpellCheck') || (v:version < 700)
    finish
endif
let g:loaded_SpellCheck = 1
let s:save_cpo = &cpo
set cpo&vim

"- configuration ---------------------------------------------------------------

if ! exists('g:SpellCheck_OnNospell')
    let g:SpellCheck_OnNospell = function('SpellCheck#AutoEnableSpell')
endif
if ! exists('g:SpellCheck_OnSpellAdd')
    let g:SpellCheck_OnSpellAdd = function('SpellCheck#SpellAddWrapper')
endif


if ! exists('g:SpellCheck_DefineAuxiliaryCommands')
    let g:SpellCheck_DefineAuxiliaryCommands = 1
endif
if ! exists('g:SpellCheck_DefineQuickfixMappings')
    let g:SpellCheck_DefineQuickfixMappings = 1
endif

if ! exists('g:SpellCheck_ErrorContextNum')
    let g:SpellCheck_ErrorContextNum = 99
endif

" From :help spellfile-cleanup:
"   Vim uses a fixed method to recognize a word.  This is independent of
"   'iskeyword', so that it also works in help files and for languages that
"   include characters like '-' in 'iskeyword'. [...]
"   The table with word characters is stored in the main .spl file.
" Since we cannot easily query that table, approximate the set of characters.
if ! exists('g:SpellCheck_SpellWordPattern')
    let g:SpellCheck_SpellWordPattern = '[[:alnum:]'']'
endif

if ! exists('g:SpellCheck_ErrorContextPattern')
    let g:SpellCheck_ErrorContextPattern = '\%(' . g:SpellCheck_SpellWordPattern . '*\%(' . g:SpellCheck_SpellWordPattern . '\@!\S\)\+\|' . g:SpellCheck_SpellWordPattern . '\+\s\+\)\?%s.' . g:SpellCheck_SpellWordPattern . '*\%(\%(' . g:SpellCheck_SpellWordPattern . '\@!\S\)\+' . g:SpellCheck_SpellWordPattern . '*\|\s\+' . g:SpellCheck_SpellWordPattern . '\+\)\?'
endif

if ! exists('g:SpellCheck_IsQuickfixHighlight')
    let g:SpellCheck_IsQuickfixHighlight = 1
endif


"- mappings --------------------------------------------------------------------

if g:SpellCheck_DefineQuickfixMappings || g:SpellCheck_IsQuickfixHighlight
    augroup SpellCheckQuickfixMappings
	" Note: Cannot use the QuickFixCmdPost event directly, as it does not
	" necessarily fire in the quickfix window! Fortunately, a BufRead event
	" for file "quickfix" is posted whenever a quickfix or location list
	" window is opened. (And the filetype is (re-)set afterwards, too.)
	" So, we use the QuickFixCmdPost event as a trigger to create the
	" mappings (once!) for the quickfix window when it is opened.
	autocmd! QuickFixCmdPost spell,lspell
	\   autocmd! SpellCheckQuickfixMappings BufRead quickfix
	\       if g:SpellCheck_DefineQuickfixMappings |
	\           call SpellCheck#mappings#MakeMappings() |
	\       endif |
	\       if g:SpellCheck_IsQuickfixHighlight |
	\           call SpellCheck#quickfix#DefineHighlights() |
	\       endif |
	\       autocmd! SpellCheckQuickfixMappings BufRead quickfix
    augroup END
endif


"- commands --------------------------------------------------------------------

if g:SpellCheck_DefineAuxiliaryCommands
    command! -bar -bang -range=%                         BDeleteUnlessSpellError     if ! SpellCheck#CheckErrors(<line1>, <line2>, 0)      | bdelete<bang>      | endif
    command! -bar -bang -range=% -nargs=* -complete=file WriteUnlessSpellError       if ! SpellCheck#CheckErrors(<line1>, <line2>, 0)      | write<bang> <args> | endif
    command! -bar -bang -range=% -nargs=* -complete=file WriteDeleteUnlessSpellError if ! SpellCheck#CheckErrors(<line1>, <line2>, 0)      | write<bang> <args> | bdelete<bang> | endif
    command! -bar -bang -range=%                         XitUnlessSpellError         if ! SpellCheck#CheckErrors(<line1>, <line2>, 0)      | write<bang>        | quit<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=file NextUnlessSpellError        if ! SpellCheck#CheckErrors(<line1>, <line2>, 0)      | next<bang> <args> | endif

    command! -bar -bang -range=%                         BDeleteOrSpellCheck         if ! SpellCheck#quickfix#List(<line1>, <line2>, 0, 0) | bdelete<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=file WriteOrSpellCheck           if ! SpellCheck#quickfix#List(<line1>, <line2>, 0, 0) | write<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=file WriteDeleteOrSpellCheck     if ! SpellCheck#quickfix#List(<line1>, <line2>, 0, 0) | write<bang> | bdelete<bang> | endif
    command! -bar -bang -range=%                         XitOrSpellCheck             if ! SpellCheck#quickfix#List(<line1>, <line2>, 0, 0) | write<bang> | quit<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=file NextOrSpellCheck            if ! SpellCheck#quickfix#List(<line1>, <line2>, 0, 0) | next<bang> <args> | endif

    command! -bar -bang -range=% UpdateAndSpellCheck         update<bang> | call SpellCheck#quickfix#List(<line1>, <line2>, 0, 0)
endif

command! -bar -bang -range=% SpellCheck  call SpellCheck#quickfix#List(<line1>, <line2>, <bang>0, 0)
command! -bar -bang -range=% SpellLCheck call SpellCheck#quickfix#List(<line1>, <line2>, <bang>0, 1)


"- highlight groups ------------------------------------------------------------

if g:SpellCheck_IsQuickfixHighlight
    highlight def link qfSpellErrorWord             SpellBad
    highlight def link qfSpellErrorWordInContext    Normal
    highlight def link qfSpellContext               SpecialKey
endif

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

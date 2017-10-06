" SpellCheck.vim: Work with spelling errors.
"
" DEPENDENCIES:
"   - Requires Vim 7.0 or higher.
"   - SpellCheck.vim autoload script
"   - SpellCheck/quickfix.vim autoload script
"   - ingo/plugin/cmdcomplete.vim autoload script
"
" Copyright: (C) 2011-2017 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>

" Avoid installing twice or when in unsupported Vim version.
if exists('g:loaded_SpellCheck') || (v:version < 700)
    finish
endif
let g:loaded_SpellCheck = 1
let s:save_cpo = &cpo
set cpo&vim

"- constants -------------------------------------------------------------------

let g:SpellCheck_ErrorTypes = ['bad', 'rare', 'local', 'caps']


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

if ! exists('g:SpellCheck_QuickfixHighlight')
    let g:SpellCheck_QuickfixHighlight = 1
endif

if ! exists('g:SpellCheck_ConsideredErrorTypes')
    let g:SpellCheck_ConsideredErrorTypes = []
endif
if ! exists('g:SpellCheck_Predicates')
    let g:SpellCheck_Predicates = ''
endif


"- mappings --------------------------------------------------------------------

if g:SpellCheck_DefineQuickfixMappings || g:SpellCheck_QuickfixHighlight
    augroup SpellCheckQuickfixMappings
	autocmd!
	" Note: Cannot use the QuickFixCmdPost event directly, as it does not
	" necessarily fire in the quickfix window! Fortunately, a BufRead event
	" for file "quickfix" is posted whenever a quickfix or location list
	" window is opened. (And the filetype is (re-)set afterwards, too.)
	" So, we use the QuickFixCmdPost event as a trigger to create the
	" mappings for the quickfix window when it is opened.
	autocmd QuickFixCmdPost spell,lspell
	\   let g:SpellCheck_IsQuickfixHighlightActive = g:SpellCheck_QuickfixHighlight |
	\   autocmd! SpellCheckQuickfixMappings BufRead quickfix
	\       if g:SpellCheck_DefineQuickfixMappings |
	\           call SpellCheck#mappings#MakeMappings() |
	\       endif
	" As a new scratch buffer is created whenever the quickfix window is
	" opened, the autocmd has to persist to embellish future ones (i.e.
	" after :cclose | :copen). But we stop embellishing when a different
	" quickfix source is used:
	autocmd QuickFixCmdPost *
	\   if expand('<afile>') !~# '^l\?spell' |
	\       let g:SpellCheck_IsQuickfixHighlightActive = 0 |
	\       execute 'autocmd! SpellCheckQuickfixMappings BufRead quickfix' |
	\   endif
    augroup END
endif


"- commands --------------------------------------------------------------------

call ingo#plugin#cmdcomplete#MakeFixedListCompleteFunc(g:SpellCheck_ErrorTypes, 'SpellCheckCompleteFunc')

if g:SpellCheck_DefineAuxiliaryCommands
    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc BDeleteUnlessSpellError     if ! SpellCheck#CheckErrors(<line1>, <line2>, 0, <q-args>)      | bdelete<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc WriteUnlessSpellError       if ! SpellCheck#CheckErrors(<line1>, <line2>, 0, <q-args>)      | write<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc WriteDeleteUnlessSpellError if ! SpellCheck#CheckErrors(<line1>, <line2>, 0, <q-args>)      | write<bang> | bdelete<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc XitUnlessSpellError         if ! SpellCheck#CheckErrors(<line1>, <line2>, 0, <q-args>)      | write<bang> | quit<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc NextUnlessSpellError        if ! SpellCheck#CheckErrors(<line1>, <line2>, 0, <q-args>)      | next<bang> | endif

    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc BDeleteOrSpellCheck         if ! SpellCheck#quickfix#List(<line1>, <line2>, 0, 0, <q-args>) | bdelete<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc WriteOrSpellCheck           if ! SpellCheck#quickfix#List(<line1>, <line2>, 0, 0, <q-args>) | write<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc WriteDeleteOrSpellCheck     if ! SpellCheck#quickfix#List(<line1>, <line2>, 0, 0, <q-args>) | write<bang> | bdelete<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc XitOrSpellCheck             if ! SpellCheck#quickfix#List(<line1>, <line2>, 0, 0, <q-args>) | write<bang> | quit<bang> | endif
    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc NextOrSpellCheck            if ! SpellCheck#quickfix#List(<line1>, <line2>, 0, 0, <q-args>) | next<bang> | endif

    command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc UpdateAndSpellCheck         update<bang> | call SpellCheck#quickfix#List(<line1>, <line2>, 0, 0, <q-args>)
endif

command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc SpellCheck  call SpellCheck#quickfix#List(<line1>, <line2>, <bang>0, 0, <q-args>)
command! -bar -bang -range=% -nargs=* -complete=customlist,SpellCheckCompleteFunc SpellLCheck call SpellCheck#quickfix#List(<line1>, <line2>, <bang>0, 1, <q-args>)

let &cpo = s:save_cpo
unlet s:save_cpo
" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

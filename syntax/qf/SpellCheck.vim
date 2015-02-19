" qf/SpellCheck.vim: Additional syntax definitions for spelling errors and their context.
"
" DEPENDENCIES:
"
" Copyright: (C) 2014 Ingo Karkat
"   The VIM LICENSE applies to this script; see ':help copyright'.
"
" Maintainer:	Ingo Karkat <ingo@karkat.de>
"
" REVISION	DATE		REMARKS
"	001	23-Jul-2014	file creation

if ! exists('g:SpellCheck_IsQuickfixHighlightActive') || ! g:SpellCheck_IsQuickfixHighlightActive
    finish  " Only apply the syntax additions when the quickfix window actually contains spelling errors, to avoid messing up errors from unrelated sources.
endif

if exists('+regexpengine') " {{{2
    " XXX: The new NFA-based regexp engine has a problem with the /\@<= pattern
    " in combination with a back reference \1; cp.
    " http://article.gmane.org/gmane.editors.vim.devel/46596
    let s:regexpPrefix = '\%#=1'
else
    let s:regexpPrefix = ''
endif

let s:countAndMessageExpr = '\%( (\d\+)\)\?\%( \[[^]]\+\]\)\?'
execute 'syntax match qfSpellErrorWord "| \zs' . g:SpellCheck_SpellWordPattern . '\+\%(' . s:countAndMessageExpr . '\%($\|\t\t\)\)\@=" nextgroup=qfSpellContext'
syntax match qfSpellContext "\t\t.*$" contains=qfSpellErrorWordInContext
execute 'syntax match qfSpellErrorWordInContext "' . s:regexpPrefix . '\%(| \1' . s:countAndMessageExpr . '\t\t.*\)\@<=\(' . g:SpellCheck_SpellWordPattern . '\+\)" contained'


highlight def link qfSpellErrorWord             SpellBad
highlight def link qfSpellErrorWordInContext    Normal
highlight def link qfSpellContext               SpecialKey

" vim: set ts=8 sts=4 sw=4 noexpandtab ff=unix fdm=syntax :

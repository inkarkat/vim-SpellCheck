SPELL CHECK
===============================================================================
_by Ingo Karkat_

DESCRIPTION
------------------------------------------------------------------------------

Vim offers built-in spell checking; when you enable it via 'spell' and
'spelllang', you can jump to the highlighted spelling errors in the buffer via
]s. With spelling errors scattered across a large document, Vim does not
provide an overview or report about the overall spell situation.

This plugin populates the |quickfix|-list with all spelling errors found in a
buffer to give you that overview. You can use the built-in quickfix features
to navigate to the first occurrence of a particular spell error. You can also
manage the spelling errors (mark as good / bad word, globally replace with
suggestion) directly from the quickfix window via the usual zg, zw, z=
etc. mappings.

A typical workflow (e.g. when composing email, commit messages, or any form of
documentation) includes writing and/or quitting the buffer, unless some
remaining spelling errors require further intervention. This plugin offers
auxiliary enhanced variants of :bdelete, :write and :quit that check for
spelling errors and only execute the action if none were found. So by using
these replacement commands, you'll never send or commit messages full of
embarrassing typos any more!

USAGE
------------------------------------------------------------------------------

    :[range]SpellCheck[!] [bad | rare | local | caps] [...] [{predicates}]
                            Show all / the passed type(s) of spelling errors as a
                            quickfix list [at locations where {predicates} yield
                            true] SpellCheck-predicates.
                            For multiple occurrences of the same error, the first
                            location and the number of occurrences is shown.
                            If [!] is not given the first error is jumped to.

                            In the quickfix list, spelling errors from other
                            buffers are kept, so you can use something like
                                :argdo SpellCheck
                            to gather the spelling errors from multiple buffers.

    :[range]SpellLCheck[!] [bad | rare | local | caps] [...] [{predicates}]
                            Same as :SpellCheck, except the location list for the
                            current window is used instead of the quickfix list.

    You can pass arbitrary Vimscript expressions that then need to match at the
    current spell error location to consider the spelling error; else, that
    particular error will be ignored. For example, the following will ignore spell
    errors in a Vim modeline:
        :SpellCheck getline('.') !~ 'vim:'
    If you define the following syntactic sugar function (in your vimrc)
        function! Syntax( pattern )
            return ingo#syntaxitem#IsOnSyntax(getpos('.'), a:pattern)
        endfunction
    you can easily limit spell checking to certain syntax elements, e.g. to
    exclude spell errors inside comments:
        :SpellCheck !Syntax('Comment')

### MAPPINGS
                            Inside the quickfix window, the following mappings are
                            remapped so that they operate on the target spell
                            error: zg, zG, zw, zW, zug, zuG, zuw,
                            zuW, z=, u
                            For z=, all identical misspellings in the buffer are
                            replaced with the chosen suggestion (via
                            :spellrepall).
                            You can also quickly undo the last spell suggestion
                            from the quickfix window (i.e. without switching to
                            the target buffer) via u.
                            For the other commands, the taken action is appended
                            to the quickfix list entry, so that the list serves as
                            a record of done actions (until you refresh the list
                            with a new :SpellCheck).

### AUXILIARY COMMANDS

    The following set of commands just issue an error when spelling errors exist
    in the buffer or passed [range] of lines.

    :BDeleteUnlessSpellError[!] [bad | rare | local | caps] [...] [{predicates}]
                                    :bdelete| the current buffer, unless it
                                    contains spelling errors.
    :WriteUnlessSpellError[!] [bad | rare | local | caps] [...] [{predicates}]
                                    :write the current buffer, unless it
                                    contains spelling errors.
    :WriteDeleteUnlessSpellError[!]  [bad | rare | local | caps] [...] [{predicates}]
                                    :write and :bdelete the current buffer,
                                    unless it contains spelling errors.
    :XitUnlessSpellError[!] [bad | rare | local | caps] [...] [{predicates}]
                                    :write  the current buffer and :quit,
                                    unless it contains spelling errors.

    :NextUnlessSpellError[!] [bad | rare | local | caps] [...] [{predicates}]
                                    Edit :next file, unless the current buffer
                                    contains spelling errors.

    This set of commands automatically opens the quickfix list in case of spelling
    error in the buffer or passed [range] of lines.

    :BDeleteOrSpellCheck[!] [bad | rare | local | caps] [...] [{predicates}]
                                    :bdelete the current buffer, or show the
                                    spelling errors in the quickfix list.
    :WriteOrSpellCheck[!] [bad | rare | local | caps] [...] [{predicates}]
                                    :write the current buffer, or show the
                                    spelling errors in the quickfix list.
    :WriteDeleteOrSpellCheck[!] [bad | rare | local | caps] [...] [{predicates}]
                                    :write and :bdelete the current buffer,
                                    or show the spelling errors in the quickfix
                                    list.
    :XitOrSpellCheck[!] [bad | rare | local | caps] [...] [{predicates}]
                                    :write the current buffer and :quit, or
                                    show the spelling errors in the quickfix list.

    :NextOrSpellCheck[!] [bad | rare | local | caps] [...] [{predicates}]
                                    Edit :next file, or show the current
                                    buffer's spelling errors in the quickfix list.

    :UpdateAndSpellCheck[!] [bad | rare | local | caps] [...] [{predicates}]
                                    :update the current buffer, and show any
                                    spelling errors in the quickfix list.

                                    A [!] is passed to the :write / :bdelete /
                                    :quit commands.

INSTALLATION
------------------------------------------------------------------------------

The code is hosted in a Git repo at
    https://github.com/inkarkat/vim-SpellCheck
You can use your favorite plugin manager, or "git clone" into a directory used
for Vim packages. Releases are on the "stable" branch, the latest unstable
development snapshot on "master".

This script is also packaged as a vimball. If you have the "gunzip"
decompressor in your PATH, simply edit the \*.vmb.gz package in Vim; otherwise,
decompress the archive first, e.g. using WinZip. Inside Vim, install by
sourcing the vimball or via the :UseVimball command.

    vim SpellCheck*.vmb.gz
    :so %

To uninstall, use the :RmVimball command.

### DEPENDENCIES

- Requires Vim 7.0 or higher.
- Requires the ingo-library.vim plugin ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)), version 1.024 or
  higher.
- repeat.vim ([vimscript #2136](http://www.vim.org/scripts/script.php?script_id=2136)) plugin (optional)
- visualrepeat.vim ([vimscript #3848](http://www.vim.org/scripts/script.php?script_id=3848)) plugin (optional)

CONFIGURATION
------------------------------------------------------------------------------

For a permanent configuration, put the following commands into your vimrc:

If you don't want the auxiliary commands, just the core :SpellCheck command,
use:

    let g:SpellCheck_DefineAuxiliaryCommands = 0

If you just want some of the auxiliary commands, or under different names, or
similar commands, you can easily define them yourself, as the core spell check
functionality is available as global autoload functions. Have a look at
plugin/SpellCheck.vim for inspiration.

If you don't want the SpellCheck-mappings that allow you to manage the spell
errors directly from the quickfix window, use:

    let g:SpellCheck_DefineQuickfixMappings = 0

The :SpellCheck command captures not just the misspelled word, but also some
text around it, to provide context in the quickfix list. The number of
occurrences of a particular spell error is set at:

    let g:SpellCheck_ErrorContextNum = 99

You can tweak that, reduce it to 1 to only show the first, or 0 to completely
turn off context.

What text around the current spell error gets captured can be tweaked via a
regular expression that contains a %s parameter, which is replaced with the
atom for the spell error start position. As Vim uses a special,
spellfile-dependent definition of word characters, these can be tweaked
separately.

The plugin can provide additional syntax highlighting for the quickfix window
when it contains spell errors; to turn this off, use:

    let g:SpellCheck_QuickfixHighlight = 0

To ignore some (e.g. rare) spell errors from the checks, you can define a
List of considered types; these are overwritten by any [bad | rare | local |
caps] argument(s) given to individual commands:

    let g:SpellCheck_ConsideredErrorTypes = ['bad', 'local', 'caps']

Likewise, you can specify default predicates that limit the accepted spell
errors unless any predicates are passed to the individual command:

    let g:SpellCheck_Predicates = 'getline(".") !~ "^#"'

To change the highlighting colors, redefine (after any :colorscheme command)
or link the two highlight groups:

    highlight link qfSpellErrorWord             SpellBad
    highlight link qfSpellErrorWordInContext    Normal
    highlight link qfSpellContext               SpecialKey

INTEGRATION
------------------------------------------------------------------------------

By default, 'spell' will be automatically enabled when it's off, but you must
have already set 'spelllang' for a functioning spell check. If you have
written a custom auto-detection for the languages that you
frequently use, you can integrate this here through a Funcref. The custom
function must take no arguments, and set 'spell' and 'spelllang' accordingly.

    let g:SpellCheck_OnNospell = function('SpellCheck#AutoEnableSpell')

If you want :SpellCheck to fail when 'spell' is off:

    let g:SpellCheck_OnNospell = ''

All commands that manipulate the word lists are executed through a Funcref; by
default, it automatically enables 'spell', like g:SpellCheck\_OnNospell.

CONTRIBUTING
------------------------------------------------------------------------------

Report any bugs, send patches, or suggest features via the issue tracker at
https://github.com/inkarkat/vim-SpellCheck/issues or email (address below).

HISTORY
------------------------------------------------------------------------------

##### 2.01    13-Nov-2024
- BUG: [count] of quickfix mappings gets clobbered by :normal.
- ENH: Employ optional repeat.vim / visualrepeat.vim plugins to allow repeat
  of quickfix mappings with . command from within the quickfix window.
- Skip spell checking in the quickfix window / location list window itself.

##### 2.00    06-Oct-2017
- ENH: Make all commands take optional [bad | rare | local | caps] type
  argument (the forwarded [++opt] [file] accepted by some auxiliary commands
  probably aren't very important here) and use that for limiting the checks to
  those spell error types.
- ENH: Make all commands take optional predicates that limit the checked
  locations, e.g. to text within a certain syntax group only.
- Introduce g:SpellCheck\_ConsideredErrorTypes configuration variable to limit
  the error types by default.
- Go to the first misspelling in the passed range (if any) instead of the
  first overall. I think this is more DWIM.
- Set the quickfix type to the capitalized first letter of the spell error
  type, except for the default "bad" ones. This allows for better
  differentiation than the previous lumping of rare + local as warning vs.
  errors.

__You need to update to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.024!__

##### 1.30    24-Jul-2014
- ENH: Show words surrounding the spell error. The number of captured
  occurrences is controlled by g:SpellCheck\_ErrorContextNum, what gets
  captured by g:SpellCheck\_ErrorContextPattern. Thanks to Enno Nagel for the
  suggestion.
- ENH: Add syntax highlighting for the misspelled word, the error context
  text, and occurrences of the misspelled word inside the context. Enno Nagel
  also suggested this.
- FIX: Quickfix mappings are gone when closing and reopening the quickfix
  window (:cclose | copen), because a new scratch buffer is used, but the
  autocmd BufRead quickfix has been cleared.

##### 1.21    23-Sep-2013
- Add :NextUnlessSpellError and :NextOrSpellCheck auxiliary commands.
- Allow to pass optional [++opt] [file] arguments to the :Write... commands.
- Add dependency to ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)).

__You need to separately
  install ingo-library ([vimscript #4433](http://www.vim.org/scripts/script.php?script_id=4433)) version 1.001 (or higher)!__

##### 1.20    08-May-2012
- FIX: Line range is not defined and passed for :BDeleteOrSpellCheck and other
  :...OrSpellCheck commands, resulting in a script error.
- ENH: Allow [range] for :BDeleteUnlessSpellError and other
  :...UnlessSpellError commands, too.

##### 1.13    02-May-2012
- ENH: In the quickfix list, apply undo via u to the target buffer to allow a
quick revert of a spell correction.

##### 1.12    01-May-2012
- ENH: Allow spell checking of partial buffers by allowing [range] for
:SpellCheck command.

##### 1.11    30-Apr-2012
- ENH: Capture corrected text and include in quickfix status message.

##### 1.10    30-Apr-2012
- ENH: Allow to manage the spelling errors (mark as good / bad word, globally
replace with suggestion) directly from the quickfix window via the usual zg,
zw, z= etc. mappings.

##### 1.01    14-Dec-2011
- ENH: Allow accumulating spelling errors from multiple buffers (e.g. via :argdo
SpellCheck).

##### 1.00    06-Dec-2011
- First published version.

##### 0.01    02-Dec-2011
- Started development.

------------------------------------------------------------------------------
Copyright: (C) 2011-2024 Ingo Karkat -
The [VIM LICENSE](http://vimdoc.sourceforge.net/htmldoc/uganda.html#license) applies to this plugin.

Maintainer:     Ingo Karkat &lt;ingo@karkat.de&gt;

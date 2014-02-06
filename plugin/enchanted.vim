" Author: Marcin Szamotulski
" Email:  mszamot [AT] gmail [DOT] com
" License: vim-license, see :help license

" This is a tiny vim script which makes searches with \v persitant.
" You can turnit off temporarily with 
"   let g:VeryMagic = 0
" or if you are already in the command line you can type \m or \M (see :help
" \m).
" There is also a very magic substitute
"   let g:VeryMagicSubstitute = 1 (default is 0)
" to turn it on you have to add the above line to your vimrc file.
" More over ther is a very magic global and vglobal:
"   let g:VeryMagicGlobal = 1 (default is 0)
" HowItWorks: it simply injects \v at the begining of your pattern after you
" press enter.
"
" Note: if you are using one of the two other of my plugins which are defining
" maps to <CR> in the command line, you need to update them to the latest
" version so that they will all work:
"   system : http://www.vim.org/scripts/script.php?script_id=4224
"   CommandAlias : http://www.vim.org/scripts/script.php?script_id=4250

" TODO: execute in cmd window, i.e. <c-f>.

if !exists('g:VeryMagic')
    let g:VeryMagic = 1
endif
if !exists('g:VeryMagicSubstitute')
    let g:VeryMagicSubstitute = 0
endif
if !exists('g:VeryMagicGlobal')
    let g:VeryMagicGlobal = 0
endif
if !exists('g:VeryMagicArg')
    let g:VeryMagicArg = 0
endif
if !exists('g:VeryMagicEscapeBackslashesInSearchArg')
    " This is very experimental. It has to detect when to escape the pattern
    " to not double escape it.
    let g:VeryMagicEscapeBackslashesInSearchArg = 0
endif

fun! s:VeryMagicSearch(dispatcher)
    " a:dispatcher: is crdispatcher#CRDispatcher dict
    if !(a:dispatcher.cmdtype ==# '/' || a:dispatcher.cmdtype ==# '?')
	return
    endif
    let cmdline = a:dispatcher.cmdline
    if g:VeryMagic && !empty(cmdline) && cmdline !~# '^\\v'
	let a:dispatcher.cmdline = '\v'.cmdline
    endif
endfun
call add(crdispatcher#CRDispatcher['callbacks'], function('s:VeryMagicSearch'))

" TODO: /\d\+/-5,/\w\+/+5 will work, but I am not sure why.
let s:range_pattern = 
	    \ '\v%('.
		\ '%('.
		    \ '\%|'.
		    \ '\$|'.
		    \ '\.|'.
		    \ '\\\&|'.
		    \ '\d+|'.
		    \ "['`]".'[a-zA-Z<>\[\]'."'`".']|'.
		    \ '/.{-}/|'.
		    \ '\?.{-}\?'.
		\ ')'.
		\ '\s*%([\+-]\d+)?'.
	    \ ')\s*' .
	    \ '%([,;]\s*'.
		\ '%('.
		    \ '\.|'.
		    \ '\$|'.
		    \ "['`]".'[a-zA-Z<>\[\]'."'`".']|'.
		    \ '\\\&|'.
		    \ '\d+|'.
		    \ '/.{-}/|'.
		    \ '\?.{-}\?'.
		\ ')\s*'.
		\ '\s*%([\+-]\s+)?'.
	    \ ')?'

fun! s:VeryMagicSubstitute(dispatcher)
    " a:dispatcher: is crdispatcher#CRDispatcher dict
    if !g:VeryMagicSubstitute || a:dispatcher.cmdtype !=# ':'
	return
    endif
    let cmdline = a:dispatcher.cmdline
    let pat = '^\v([[:space:]:]*'.
		    \ '%('.s:range_pattern.')?\s*'.
		    \ 's%[ubstitute]\s*'.
		    \ '([^a-zA-Z_1-9])'.
	    \ ')'.
	    \ '(.{-})'.
	    \ '(\2.*)'
    let matches = matchlist(cmdline, pat)
    if !empty(matches)
	if matches[3] !~# '^\\v' && len(matches[3])
	    let cmdline = matches[1].'\v'.matches[3].matches[4]
	endif
    endif
    let a:dispatcher.cmdline = cmdline
endfun
call add(crdispatcher#CRDispatcher['callbacks'], function('s:VeryMagicSubstitute'))

fun! s:VeryMagicGlobal(dispatcher)
    " a:dispatcher: is crdispatcher#CRDispatcher dict
    if !g:VeryMagicGlobal || a:dispatcher.cmdtype !=# ':'
	return
    endif
    let cmdline = a:dispatcher.cmdline
    let pat = '^\v([[:space:]:]*'.
		    \ '%('.s:range_pattern.')?\s*'.
		    \ '%(g%[lobal]|v%[global])!?'.
		    \ '\s*([^a-zA-Z_1-9])'.
	    \ ')'.
	    \ '(.{-})(\2.*)'
    let matches = matchlist(cmdline, pat)
    if !empty(matches)
	if matches[3] !~# '^\\v' && len(matches[3])
	    let cmdline = matches[1].'\v'.matches[3].matches[4]
	endif
    endif
    let a:dispatcher.cmdline = cmdline
endfun
call add(crdispatcher#CRDispatcher['callbacks'], function('s:VeryMagicGlobal'))

fun! s:VeryMagicVimGrep(dispatcher)
    " a:dispatcher: is crdispatcher#CRDispatcher dict
    if !g:VeryMagicVimGrep || a:dispatcher.cmdtype !=# ':'
	return
    endif
    let cmdline = a:dispatcher.cmdline
    let pat = '\v^([[:space:]:]*'.
		    \ '%(vim%[grep]|lv%[imgrep])!?'.
		    \ '\s*([^a-zA-Z_1-9])'.
	    \ ')'.
	    \ '(.{-})(\2.*)'
    let matches = matchlist(cmdline, pat)
    if !empty(matches)
	if matches[3] !~# '^\\v' && len(matches[3])
	    let cmdline = matches[1].'\v'.matches[3].matches[4]
	endif
    endif
    let a:dispatcher.cmdline = cmdline
endfun
call add(crdispatcher#CRDispatcher['callbacks'], function('s:VeryMagicVimGrep'))

fun! s:VeryMagicSearchArg(dispatcher)
    if (!g:VeryMagicSearchArg && !g:VeryMagicEscapeBackslashesInSearchArg) || a:dispatcher.cmdtype !=# ':'
	return
    endif
    let cmdline = a:dispatcher.cmdline
    let pat = '^\v([[:space:]:]*'.
		    \ '%('.
			\ 'e%[dit]!?|'.
			\ 'view?!?|'.
			\ 'vi%[sual]!?|'.
			\ 'ex|'.
			\ '\d*\s*sp%[lit]'.
			\ '\d*\s*vs%[plit]'.
			\ '\d*\s*new'.
			\ '\d*\s*vnew?'.
			\ '\d*\s*sv%[iew]'.
			\ '\d*\s*sf%[ind]'.
			\ '\d*\s*find?!?'.
		    \ ')'.
		\ ')'.
		\ '(\s.{-})'.
		\ '(\s@1<=\+/\S@=)'.
		\ '(%(\S|\\\s)+)'.
		\ '(.*)'
    let matches = matchlist(cmdline, pat)
    if !empty(matches)
	let pat = matches[4]
	if g:VeryMagicEscapeBackslashesInSearchArg && pat =~# '\v(\\@1<!\\[^\\])'
	    " TODO: it is not easy find a regex which detects if the pattern
	    " should be escaped.  The current pattern matches if there is
	    " a single '\'.
	    let pat = escape(pat, '\')
	endif
	if g:VeryMagicSearchArg && pat !~# '^\\\\v'
	    let pat = '\\v' . pat
	endif
	let a:dispatcher.cmdline = matches[1] . matches[2] . matches[3] . pat . matches[5]
    endif
endfun
call add(crdispatcher#CRDispatcher['callbacks'], function('s:VeryMagicSearchArg'))

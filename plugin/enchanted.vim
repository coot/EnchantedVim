" Author: Marcin Szamotulski
" Email:  mszamot [AT] gmail [DOT] com
" License: vim-license, see :help license

" TODO: very magic version of *

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

let g:DetectVeryMagicPattern = '\v(%(\\\\)*)@>\\v'  " or '^\\v\>'
let g:DetectVeryMagicBackslashEscapedPattern = '\v(%(\\\\\\\\)*)@>\\\\v'  " or '^\\\\v\>'
" The default matches even number of backslashes followed by v.

fun! s:VeryMagicSearch(dispatcher)
    " / and ? commands
    " a:dispatcher: is crdispatcher#CRDispatcher dict
    if !(a:dispatcher.cmdtype ==# '/' || a:dispatcher.cmdtype ==# '?')
	return
    endif
    let cmdline = a:dispatcher.cmdline
    if g:VeryMagic && !empty(cmdline) && cmdline !~# g:DetectVeryMagicPattern
	let a:dispatcher.cmdline = '\v'.cmdline
    endif
endfun
call add(crdispatcher#CRDispatcher['callbacks'], function('s:VeryMagicSearch'))

fun! <SID>VeryMagicStar(searchforward, g)
    " used to replace * and # normal commands
    " This keeps the search history clean (no no very magic patterns which
    " then would be missunderstood).  Another approach would be to use
    "	normal *
    " and only manipulate with the hisory, but this approach is more
    " consistent.
    let word = expand('<cword>')
    let pat = escape(word, '.?=@*+&()[]{}^$|/\~')
    if !a:g
	let pat = '<'.pat.'>'
    endif
    let pat = '\v'.pat
    if !a:searchforward
	" emulate vim's behaviour
	call search(pat, 'bsc')
	call search(pat, 'b')
    else
	call search(pat, 's')
    endif
    call histadd('/', pat)
endfun

if g:VeryMagic
    " We make this two maps so that the search history contains very magic
    " patterns.
    " TODO: they will fail if isk+=': escape('aaa'aaa', ...)
    nm <silent> * :call <SID>VeryMagicStar(1, 0)<CR>
    nm <silent> # :call <SID>VeryMagicStar(0, 0)<CR>
    " This map in general should not be necessary, unless isk contains
    " characters which needs to be escaped
    nm <silent> g* :call <SID>VeryMagicStar(1, 1)<CR>
    nm <silent> g# :call <SID>VeryMagicStar(0, 1)<CR>
endif

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
    " :substitute command
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
	if matches[3] !~# g:DetectVeryMagicPattern && len(matches[3])
	    let cmdline = matches[1].'\v'.matches[3].matches[4]
	endif
    endif
    let a:dispatcher.cmdline = cmdline
endfun
call add(crdispatcher#CRDispatcher['callbacks'], function('s:VeryMagicSubstitute'))

fun! s:VeryMagicGlobal(dispatcher)
    " :global and :vglobal commands
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
	if matches[3] !~# g:DetectVeryMagicPattern && len(matches[3])
	    let cmdline = matches[1].'\v'.matches[3].matches[4]
	endif
    endif
    let a:dispatcher.cmdline = cmdline
endfun
call add(crdispatcher#CRDispatcher['callbacks'], function('s:VeryMagicGlobal'))

fun! s:VeryMagicVimGrep(dispatcher)
    " :vimgrep and :lvimgrep commands
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
	if matches[3] !~# g:DetectVeryMagicPattern && len(matches[3])
	    let cmdline = matches[1].'\v'.matches[3].matches[4]
	endif
    endif
    let a:dispatcher.cmdline = cmdline
endfun
call add(crdispatcher#CRDispatcher['callbacks'], function('s:VeryMagicVimGrep'))

fun! s:VeryMagicSearchArg(dispatcher)
    " :edit +/pattern but also :view, :sview, :visual, :ex, :split, :vsplit, :new,
    " :vnew, :find, :sfind.
    if (!g:VeryMagicSearchArg && !g:VeryMagicEscapeBackslashesInSearchArg) || a:dispatcher.cmdtype !=# ':'
	return
    endif
    let cmdline = a:dispatcher.cmdline
    let pat = '^\v([[:space:]:]*'.
		    \ '%('.
			\ 'e%[dit]!?|'.
			\ 'view?!?|'.
			\ '\d*\s*sv%[iew]!?'.
			\ 'vi%[sual]!?|'.
			\ 'ex!?|'.
			\ '\d*\s*sp%[lit]!?'.
			\ '\d*\s*vs%[plit]!?'.
			\ '\d*\s*new!?'.
			\ '\d*\s*vnew?!?'.
			\ '\d*\s*find?!?'.
			\ '\d*\s*sf%[ind]!?'.
		    \ ')'.
		\ ')'.
		\ '(\s.{-})'.
		\ '(\s@1<=\+/\S@=)'.
		\ '(%(\S|\\\s)+)'.
		\ '(.*)'
    let matches = matchlist(cmdline, pat)
    if !empty(matches)
	let pat = matches[4]
	if g:VeryMagicEscapeBackslashesInSearchArg && pat =~# '\v\\@1<!\\%([^\\]|$)'
	    " TODO: it is not easy find a regex which detects if the pattern
	    " should be escaped.  The current pattern matches if there is
	    " a single '\'.
	    let pat = escape(pat, '\')
	endif
	if g:VeryMagicSearchArg && pat !~# g:DetectVeryMagicBackslashEscapedPattern
	    let pat = '\\v' . pat
	endif
	let a:dispatcher.cmdline = matches[1] . matches[2] . matches[3] . pat . matches[5]
    endif
endfun
call add(crdispatcher#CRDispatcher['callbacks'], function('s:VeryMagicSearchArg'))

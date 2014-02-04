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

fun! s:VeryMagicSearch(cmdline)
    if g:VeryMagic && !empty(a:cmdline) && a:cmdline !~# '^\\v'
	return '\v'.a:cmdline
    else
	return a:cmdline
    endif
endfun
call add(crdispatcher#CRDispatcher['/'], function('s:VeryMagicSearch'))
call add(crdispatcher#CRDispatcher['?'], function('s:VeryMagicSearch'))


let s:range_pattern = '\%('.
		\ '%\|'.
		\ '\$\|'.
		\ '\.\|'.
		\ '\\&\|'.
		\ '\d\+\|'.
		\ "'".'[a-zA-Z]\|'.
		\ '\/.\{-}\/\?'.
		\ '\|?.\{-}?\?'.
	    \ '\)\s*'.
	    \ '\%(,\s*'.
		\ '\%('.
		    \ '\.\|'.
		    \ '\$\|'.
		    \ "'".'[a-zA-Z]\|'.
		    \ '\\&\|'.
		    \ '\d\+\|'.
		    \ '\/.\{-}\/\?\|'.
		    \ '?.\{-}?\?'.
		\ '\)\s*'.
	    \ '\)\?'

fun! s:VeryMagicSubstitute(cmdline)
    if !g:VeryMagicSubstitute
	return a:cmdline
    endif
    let cmdlines = split(a:cmdline, '\\\@<!|')
    let n_cmdlines = []
    for cmdline in cmdlines
	let pat = '^\([:\s]*'.
			\ s:range_pattern.
			\ 's\%[ubstitute]\s*'.
			\ '\([^a-zA-Z_1-9]\)'.
		\ '\)'.
		\ '\(.\{-}\)'.
		\ '\(\2.*\)'
	let matches = matchlist(cmdline, pat)
	if !empty(matches)
	    if matches[3] !~# '^\\v'
		let cmdline = matches[1].'\v'.matches[3].matches[4]
	    endif
	endif
	call add(n_cmdlines, cmdline)
    endfor
    return join(n_cmdlines, '|')
endfun
call add(crdispatcher#CRDispatcher[':'], function('s:VeryMagicSubstitute'))

fun! s:VeryMagicGlobal(cmdline)
    if !g:VeryMagicGlobal
	return a:cmdline
    endif
    let cmdlines = split(a:cmdline, '\\\@<!|')
    let n_cmdlines = []
    for cmdline in cmdlines
	let pat = '^\([:\s]*'.
			\ s:range_pattern.
			\ '\%(g\%[lobal]\|v\%[global]\)!\?'.
			\ '\s*\([^a-zA-Z_1-9]\)'.
		\ '\)'.
		\ '\(.\{-}\)\(\2.*\)'
	let matches = matchlist(cmdline, pat)
	if !empty(matches)
	    if matches[3] !~# '^\\v'
		let cmdline = matches[1].'\v'.matches[3].matches[4]
	    endif
	endif
	call add(n_cmdlines, cmdline)
    endfor
    return join(n_cmdlines, '|')
endfun
call add(crdispatcher#CRDispatcher[':'], function('s:VeryMagicGlobal'))

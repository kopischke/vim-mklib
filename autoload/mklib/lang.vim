" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Return the canonical Vim code for {lang}, or the current buffer's &spelllang if omitted:
" @signature:  mklib#lang#guess([{lang:String}])
" @returns:    a language code String in canonical Vim format,
"              or '' if no language code could be extracted
" @see:        :h spell.txt
function! mklib#lang#canonize(...) abort " {{{
  let l:spelllang  = a:0 ? mklib#string#trim(a:1) : &spelllang
  if !empty(l:spelllang)
    let l:transforms = {
    \   'downcase': ['^[A-Za-z]\{2}_[A-Z]\{2}$',           '\L&',     ''],
    \   'hunspell': ['^hun-\([a-z]\{2}\)-\([A-Z]\{2}\).*', '\1_\L\2', ''],
    \ }

    for l:transform in values(l:transforms)
      let l:transformed = call(function('substitute'), extend([l:spelllang], l:transform))
      if l:transformed !=# l:spelllang
        let l:spelllang = l:transformed
        break
      endif
    endfor
  endif

  return mklib#lang#valid(l:spelllang) ? l:spelllang : ''
endfunction " }}}

" Check if {code} is a valid Vim language code:
" @signature:  mklib#lang#valid({code:String})
" @returns:    boolean Number (1/0)
" @notes:      currently only pattern matches codes
function! mklib#lang#valid(code) abort " {{{2
  return a:code =~# '\m[a-z]\{2}_[a-z]\{2}'
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=1::

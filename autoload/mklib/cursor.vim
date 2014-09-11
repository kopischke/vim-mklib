" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Get character under cursor:
" @signature:  mklib#cursor#curchar()
" @returns:    String of one (possibly multi-byte) character
function! mklib#cursor#curchar() " {{{
  return matchstr(getline('.'), '\%'.col('.').'c.')
endfunction " }}}

" Get character before the cursor:
" @signature:  mklib#cursor#nextchar()
" @returns:    String of one (possibly multi-byte) character
function! mklib#cursor#nextchar() " {{{
  return matchstr(getline('.'), '\%>'.col('.').'c.')
endfunction " }}}

" Get character after the cursor:
" @signature:  mklib#cursor#prevchar()
" @returns:    String of one (possibly multi-byte) character
function! mklib#cursor#prevchar() " {{{
  return matchstr(getline('.'), '.*\zs\%<'.col('.').'c.')
endfunction " }}}

" Get word under (or after) cursor, whitespace trimmed:
" @signature:  mklib#cursor#word([{big:Number}])
" @arguments:  'big': 0 to get <cword> (default if omitted)
"                     1 to get <cWORD>
" @returns:    the trimmed word String
" @see:        :h <cword> and :h <cWORD>
function! mklib#cursor#cword(...) abort " {{{
  let l:type = get(a:, 1, 0) ? '<cWORD>' : '<cword>'
  return mklib#string#trim(expand(l:type))
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=1::

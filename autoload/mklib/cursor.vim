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

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=1::

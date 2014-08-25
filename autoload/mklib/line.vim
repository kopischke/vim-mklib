" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Get character under cursor:
" @signature:  mklib#line#curchar()
" @returns:    String of one (possibly multi-byte) character
function! mklib#line#curchar() " {{{
  return matchstr(getline('.'), '\%'.col('.').'c.')
endfunction " }}}

" Get character before the cursor:
" @signature:  mklib#line#nextchar()
" @returns:    String of one (possibly multi-byte) character
function! mklib#line#nextchar() " {{{
  return matchstr(getline('.'), '\%>'.col('.').'c.')
endfunction " }}}

" Get character after the cursor:
" @signature:  mklib#line#prevchar()
" @returns:    String of one (possibly multi-byte) character
function! mklib#line#prevchar() " {{{
  return matchstr(getline('.'), '.*\zs\%<'.col('.').'c.')
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=1::

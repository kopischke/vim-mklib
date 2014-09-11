" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Return the library version:
" @signature:  mklib#version()
" @returns:    String: semantic version
function! mklib#version()
  return '0.2.0'
endfunction

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=0:

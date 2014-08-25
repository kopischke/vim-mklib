" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Check if {position} is inside a currently open fold:
" @signature:  mklib#fold#isopen({position:Number|String)
" @arguments:  'position': either a line Number, or a line() code String
" @returns:   -1 if the position is not inside a fold
"              0 if the position is inside a closed fold
"              1 if the position is inside an open fold
function! mklib#fold#isopen(position) abort " {{{
  let l:line = mklib#script#isnumber(a:position) ? a:position : line(a:position)
  return foldlevel(l:line) == 0 ? -1 : foldclosed(l:line) == -1 ? 1 : 0
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=1:

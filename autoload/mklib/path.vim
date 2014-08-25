" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Always return a directory path of a file system object
" (i.e., when the object is a directory, return the path to it,
" else return the path to its containing directory):
" @signature:  mklib#path#dirpath({target:String})
" @returns:    String: path to the directory
function! mklib#path#dirpath(target) abort " {{{
  let l:target = fnamemodify(expand(a:target), ':p')
  return isdirectory(l:target) ? l:target : fnamemodify(l:target, ':h')
endfunction " }}}

" Like mklib#path#dirpath (see above),
" but raise an exception if the path is not found in the file system:
" @signature: mklib#path#realdirpath({target:String})
" @returns:    String: path to the directory
" @exceptions: E605 if the path is not found in the file system
function! mklib#path#realdirpath(target) abort " {{{
  let l:target = mklib#path#dirpath(a:target)
  if !isdirectory(l:target)
    throw "Not a real directory path: ".string(a:target)
  endif
  return l:target
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=0:

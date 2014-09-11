" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Escape String literals for use in regular expressions
" @signature:  mklib#string#regex({literal:String})
" @returns:    a String escaped for literal use
function! mklib#regex#escape(literal)
  return substitute(a:string, '\\', '\\\\', 'g')
endfunction

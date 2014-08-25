" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Convenience function to check if a value is either a Number or Float
" @signature:  mklib#numeric#isnumeric({value:Any})
" @returns:    1 if {value} is either a Number or a Float, else 0
function! mklib#numeric#isnumeric(value) abort " {{{
  return mklib#script#isnumber(a:value) || mklib#script#isfloat(a:value)
endfunction " }}}

" Sort compatible compare of numeric values:
" @signature:  mklib#numeric#compare(num1:Number|Float, num2:Number|Float)
" @returns:    0 if {num1} and {num2} are equal,
"              1 if {num1} is bigger than {num2},
"             -1 if {num1} is smaller than {num2}
" @exceptions: E605 if either argument is not numeric
" @notes:      designed for use with the sort() function
function! mklib#numeric#compare(num1, num2) abort " {{{
  if !mklib#numeric#isnumeric(a:num1) || !mklib#numeric#isnumeric(a:num2)
    throw "Can only compare numeric values: ".string(a:num1)." : ".string(a:num2)
  endif
  return a:num1 == a:num2 ? 0 : a:num1 > a:num2 ? 1 : -1
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=0:

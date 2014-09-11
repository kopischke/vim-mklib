" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Test if if all keys of {filter} are in {dict} and the values match:
" @signature:  mklib#dict#conforms({dict:Dictionary}, {filter:Dictionary}[, {options:Dictionary}])
" @options:
" - 'ignorecase'  match values with or without case (default: &ignorecase)
" - 'pattern'     match values as a pattern, not a literal (default: 0)
" @returns:    Boolean Number (1/0)
function! mklib#dict#conforms(dict, filter, ...) " {{{
  let l:ignorecase = a:0 ? get(a:1, 'ignorecase', &ignorecase) : &ignorecase
  let l:pattern    = a:0 ? get(a:1, 'pattern', 0) : 0
  let l:operator   = ' !'.(l:pattern ? '~' : '=').(l:ignorecase ? '?' : '#').' '
  for l:key in keys(a:filter)
    if !has_key(a:dict, l:key) || eval('a:dict[l:key]'.l:operator.'a:filter[l:key]')
      return 0
     endif
  endfor
  return 1
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=0:

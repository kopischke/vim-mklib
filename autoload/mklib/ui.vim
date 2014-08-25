" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Print a warning message:
" @signature:  mklib#script#warn({message:String})
" @returns:    nothing
" @notes:      use the 'WarningMsg' highlight group
function! mklib#ui#warn(message) " {{{
  echohl WarningMsg
  try
    execute 'echo"'.a:message.'"'
  finally
    echohl None
  endtry
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=0:

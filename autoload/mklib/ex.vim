" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Join an arbitrary number of {cmd} Strings or Lists into a one-line command:
" @signature:  mklib#ex#joincmd({cmd:String|List}[, {cmd}[, ...]])
" @returns:    String usable for :execute
" @notes:      List {cmd} arguments are only flattened one level
function! mklib#ex#joincmd(...) abort " {{{
  let l:sep  = ' | '
  let l:cmds = a:0 ? deepcopy(a:000) : []
  return join(map(l:cmds, 'mklib#ex#islist(v:val) ? join(v:val, l:sep) : v:val'), l:sep)
endfunction " }}}

" Get the output of {cmd}:
" @signature:  mklib#ex#out({cmd:String})
" @returns:    {cmd} output String
" @notes:      execution of {cmd} is silent
function! mklib#ex#out(cmd) abort " {{{
  try
    redir => l:out
    silent execute a:cmd
  finally
    redir END
  endtry
  return l:out
endfunction " }}}

" Parse the output of {cmd} into a List by splitting on {sep}:
" @signature:  mklib#ex#outlist({cmd:String}[, {sep:String}])
" @returns:    List of {cmd} output split on {sep} ('\n' if omitted)
" @notes:      execution of {cmd} is silent
function! mklib#ex#outlist(cmd, ...) abort " {{{
  return split(mklib#ex#out(a:cmd), get(a:, 1, '\n'))
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=0:

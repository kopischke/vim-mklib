" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Iron out shellescape()'s bugs:
" @signature:  mklib#shell#escape({string:String}[, {shell:String}])
" @arguments: 'shell': type of shell to escape for (default: &shell)
" @returns:    an escaped String ready for shell usage
function! mklib#shell#escape(string, ...) abort " {{{
  let l:escaped = shellescape(a:string)
  let l:shell   = a:0 ? a:1 : &shell
  if l:shell =~? '[\_^ /]bash$'
    " escaping single quotes is not valid in Bash
    " see http://www.gnu.org/software/bash/manual/bashref.html#Single-Quotes
    let l:escaped = substitute(l:escaped, "'\\\\''", "'\"'\"'", 'g')
  endif
  return l:escaped
endfunction " }}}

" Run an external command with the best available system call:
" @signature:  mklib#shell#execute({command:String}[, {input:String}])
" @returns:    the String output of the command
" @notes:      uses vimproc#system() if available, which ignores shell
"              internals (:h vimproc#system())
function! mklib#shell#execute(command, ...) abort " {{{
  let l:system = s:use_vimproc() ? 'vimproc#system' : 'system'
  return call(l:system, extend([a:command], a:000))
endfunction " }}}

" Get the last status of mklib#shell#execute:
" @signature:  mklib#shell#status()
" @returns:    the last shell exit status Number
function! mklib#shell#status() abort " {{{
  return s:use_vimproc() ? vimproc#get_last_status() : v:shell_error
endfunction " }}}

" Helper functions {{{
function! s:use_vimproc() abort
  let g:mklib#shell#use_vimproc = get(g:, 'mklib#shell#use_vimproc', exists('*vimproc#system'))
endfunction
" }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=1:

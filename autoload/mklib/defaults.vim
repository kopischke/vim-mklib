" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Get the value of {name} in the first relevant scope:
" @signature:  mklib#defaults#get({name:String}[, {default:Any}][, {options:Dictionary}])
" @options:    'scopes'  List of scope name Strings, in order of priority.
" @returns:    the value found in the first relevant scope, or {default} if set, else 0
" @notes:      for default scope order see mklib#defaults#scopes()
function! mklib#defaults#get(name, ...) abort " {{{
  let l:args   = mklib#script#optparse(a:000, 2)
  let l:scopes = call(function('mklib#defaults#scopes'), get(l:args.opts, 'scopes', []))
  for l:scope in l:scopes
    if exists(l:scope.a:name)
      return {l:scope}{a:name}
    endif
  endfor
  return get(l:args.args, 0, 0)
endfunction " }}}

" Unlet all {name} defaults in scopes below {scope} ('global' if not specified):
" @signature:  mklib#defaults#reset({name:String}[, {scope:String}])
" @returns:    the value of {name} in {scope}
function! mklib#defaults#reset(name, ...) abort " {{{
  let l:target     = mklib#defaults#scopes(get(a:, 1, 'global'))[0]
  let l:scopes     = mklib#defaults#scopes()
  let l:target_idx = match(l:scopes, l:target)
  if  l:target_idx > 0
    for l:scope in l:scopes[: l:target_idx-1]
      unlet! {l:scope}{a:name}
    endfor
  endif
  return mklib#defaults#get(a:name)
endfunction " }}}

" Get applicable scope codes:
" @signature:  mklib#defaults#scopes([{scope:String}[, {scope:String}[...]]])
" @arguments:  scope name Strings in the order the codes should be returned;
"              valid values are 'buffer', 'global' and 'tab', 'window' if +windows
" @returns:    List of valid scope codes, in default order or matching provided arguments
" @notes:      the default scope order is 'buffer'[, 'window', 'tab'], 'global'
function! mklib#defaults#scopes(...) abort " {{{
  let l:codes  = {'buffer': 'b:', 'global': 'g:'}
  if has('windows')
    call extend(l:codes, {'window': 'w:', 'tab': 't:'})
  endif
  let l:scopes = copy(a:0 ? a:000 : ['buffer', 'window', 'tab', 'global'])
  return filter(map(l:scopes, 'get(l:codes, v:val, "")'), '!empty(v:val)')
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=0:

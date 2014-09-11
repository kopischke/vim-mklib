" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Convenience function to check if a value is either a List or a Dictionary:
" @signature:  mklib#collection#iscollection({value:Any})
" @returns:    1 if {value} is either a List or a Dictionary, else 0
function! mklib#collection#iscollection(value) abort " {{{
  return mklib#script#isdict(a:value) || mklib#script#islist(a:value)
endfunction " }}}

" Check for an entry in a List or Dictionary with 'has_key()' semantics:
" @signature:  mklib#collection#has_value({collection:List|Dictionary}, {value:String})
" @returns:    1 if an entry is present, 0 otherwise
function! mklib#collection#has_value(collection, value) abort " {{{
  return mklib#collection#match(a:collection, a:value, {'full': 1, 'ignorecase': 0, 'pattern': 0}) > -1
endfunction " }}}

" Match both Lists and Dictionaries with the semantics of 'match()':
" @signature:  mklib#collection#match({collection:List|Dictionary},
"              {pattern:String}[, {index:Number}[, {count:Number}]][, {options:Dictionary])
" @options:
" - 'full'        to match as if the pattern was enclosed in '^...$' (default: 0)
" - 'ignorecase'  0/1 to override &ignorecase (default: &ignorecase)
" - 'pattern'     0 to match literally, 1 to match as pattern (default: 1)
" @returns:    Number index (for Lists) or String key (for Dictionaries)
" @exceptions: E605 if {collection} is not a List or Dictionary
" @notes:      Dictionary items are processed in alphabetical order of their keys
function! mklib#collection#match(collection, pattern, ...) abort " {{{
  if !mklib#collection#iscollection(a:collection)
    throw 'Not a collection type: '.string(a:collection)
  endif

  " gather optional arguments, trailing dict = opts dict
  let l:optargs = mklib#script#optparse(a:000, 3)
  let l:start   = get(l:optargs.args, 0, 0)
  let l:count   = get(l:optargs.args, 1, 1)

  " options dict values with defaults
  let l:optargs.opts.ignorecase = get(l:optargs.opts, 'ignorecase', &ignorecase)
  let l:optargs.opts.pattern    = get(l:optargs.opts, 'pattern', 1)
  let l:optargs.opts.full       = get(l:optargs.opts, 'full', 0)

  " generate match() search pattern
  let l:seek    = l:optargs.opts.ignorecase ? '\c' : '\C'
  if !l:optargs.opts.pattern
    let l:seek .= '\V'.substitute(a:pattern, '\', '\\', 'g')
    let l:end   = '\$'
  else
    let l:seek .= '\%('.substitute(a:pattern, '\%(\\_\)\@<![$^]', '\\_&', 'g').'\)'
    let l:end   = '$'
  endif
  let l:seek    = l:optargs.opts.full ? '^'.l:seek.l:end : l:seek

  if mklib#script#islist(a:collection)
    return call('match', [a:collection, l:seek, l:start, l:count])
  else
    let l:targets = sort(keys(a:collection))[l:start :]
    let l:match   = filter(l:targets, 'match(a:collection[v:val], l:seek) > -1')
    return len(l:match) >= l:count ? l:match[l:count-1] : -1
  endif
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=0:

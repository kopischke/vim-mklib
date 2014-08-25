" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" Retrieve a map properties Dictionary for {key} and {mode},
" optionally resolving <Plug> maps if {flatten} is 1:
" @signature:  mklib#map#get({key:String}, {mode:String}[, {flatten:Number}])
" @returns:    a map options Dictionary (empty if no map is found)
function! mklib#map#get(key, mode, ...) abort " {{{
  let l:map     = mklib#map#heuristics(maparg(a:key, a:mode, 0, 1))
  let l:flatten = a:0 ? a:1 : 0
  return empty(l:map) || !l:flatten ? l:map : mklib#map#unplug(l:map)
endfunction " }}}

" Get a list of all maps for {key} and {mode} or {filter}:
" @signature:  mklib#map#list({key:String}, {mode:String}|{filter:Dictionary})
" @returns:    a List of map Strings matching {key} in {mode}
" @notes:      semantics are as in the :[{mode}][nore]map command,
"              i.e. partial and empty {key}s are valid
function! mklib#map#list(key, ...) abort " {{{
  let l:filter  = a:0 && mklib#script#isdict(a:1) ? deepcopy(a:1) : {}
  let l:mode    = get(l:filter, 'mode', a:0 && mklib#script#isstring(a:1) ? a:1 : '')
  let l:noremap = get(l:filter, 'noremap', 0)

  " remove keys already filtered by the :{mode}[nore]map call
  for l:key in ['mode']
    if has_key(l:filter, l:key)
      unlet l:filter[l:key]
    endif
  endfor

  " collect matching maps
  let l:cmd  = mklib#map#cmd4mode(l:noremap ? 'noremap' : 'map', l:mode)
  let l:out  = mklib#script#out2list(l:cmd.' '.a:key)
  let l:maps = map(filter(l:out, 'v:val !=? "No mapping found"'), 'split(v:val, "\\s\\+")[1]')

  return empty(l:filter) ? l:maps : filter(l:maps, 'mklib#map#exists(v:val, l:filter)')
endfunction " }}}

" Detect if a map for {key} and {mode} or {filter} exists:
" @signature:  mklib#map#exists({key:String}, {mode:String}|{filter:Dictionary})
" @returns:    1 if a matching map exists, 0 otherwise
" @notes:
" - the 'lhs' key in {filter} is ignored
" - the 'script' key in {filter} is only compared when present in {key}'s map
" - any other keys not returned by maparg() with the dict option are ignored
function! mklib#map#exists(key, ...) abort " {{{
  let l:filter = a:0 && mklib#script#isdict(a:1) ? deepcopy(a:1) : {}
  let l:mode   = get(l:filter, 'mode', a:0 && mklib#script#isstring(a:1) ? a:1 : '')
  let l:map    = maparg(a:key, l:mode, 0, 1)
  if empty(l:map)
    return 0
  elseif empty(l:filter)
    return 1
  endif

  " sanitize filter
  " - ignore invalid keys and 'lhs' (as we get our data from {key})
  let l:valid_keys = ['rhs', 'silent', 'noremap', 'expr', 'buffer', 'mode', 'sid', 'nowait', 'script']
  let l:filter     = filter(l:filter, 'mklib#collection#has_value(l:valid_keys, v:key)')
  " - only compare 'script' if present in both
  if has_key(l:filter, 'script')
    let l:map      = mklib#map#heuristics(l:map)
    if !has_key(l:map, 'script')
      unlet l:filter.script
    endif
  endif

  return mklib#dict#conforms(l:map, l:filter)
endfunction " }}}

" Try to supplement map data by applying some heuristics:
" @signature:  mklib#map#heuristics({map:Dictionary})
" @returns:    a copy of {map} with the detected options set
" @notes:      currently only does naive <script> detection
function! mklib#map#heuristics(map) abort " {{{
  let l:map = deepcopy(a:map)

  " <script> heuristics. Shortcut:
  " - empty RHS (nothing to check)
  " - remappable maps (no way to guess if these are 'script')
  " - declared 'script' maps (no need to guess any more)
  if !empty(get(l:map, 'rhs', '')) && get(l:map, 'noremap', 0) && !has_key(l:map, 'script')
    let l:filter = {'mode': get(l:map, 'mode', ''), 'noremap': 1}
    let l:spliced = mklib#map#splice(l:map)

    " strategies for noremap maps:
    " - contains same SID <SID> maps: probably a 'script' map
    if has_key(l:map, 'sid')
      let l:snr = '<SNR>'.l:map.sid.'_'
      let l:sidmaps = map(
      \   reverse(sort(mklib#map#list(l:snr, l:filter.mode))),
      \   'substitute(v:val, l:snr, "<SID>", "")'
      \ )

      for l:sidmap in l:sidmaps
        if len(filter(copy(l:spliced.literal), 'match(v:val, l:sidmap) > -1')) > 0
          let l:map.script = 1
          break
        endif
      endfor
    endif

    " - contains any <SNR> map: probably a 'script' map
    if !get(l:map, 'script', 0)
      let l:snrmaps = reverse(sort(mklib#map#list('<SNR>', l:filter.mode)))
      for l:snrmap in l:snrmaps
        if len(filter(copy(l:spliced.literal), 'match(v:val, l:snrmap) > -1')) > 0
          let l:map.script = 1
          break
        endif
      endfor
    endif

    " - contains neither: probably not a 'script' map
    let l:map.script = get(l:map, 'script', 0)
  endif

  return l:map
endfunction " }}}

" Resolves <Plug> maps to their terminal {map} options Dictionary:
" @signature:  mklib#map#unplug({map:Dictionary})
" @returns:    a copy of {map} with the <Plug> resolved in {map.rhs} and
"              options set to match the terminal RHS
" @notes:      operates recursively, but only resolves pure <Plug> maps,
"              i.e. those whose RHS consist exclusively of one <Plug>
function! mklib#map#unplug(map) abort " {{{
  let l:map      = mklib#map#heuristics(a:map)
  let l:map_mode = get(a:map, 'mode', '')
  let l:map_rhs  = get(a:map, 'rhs',  '')

  " no resolving in maps
  " - that ignore the <Plug> map (i.e. 'noremap' and <script>)
  " - which cannot be pure <Plug> maps (i.e. <expr>)
  " - whose RHS does not contain '<Plug>'
  if   get(l:map, 'noremap', 0)
  \ || get(l:map, 'script', 0)
  \ || get(l:map, 'expr', 0)
  \ || match(l:map_rhs, '\c<plug>') == -1
     return l:map
  endif

  " get a list of <Plug> maps and the literals to match
  let l:plugmaps = mklib#map#list('<Plug>', l:map_mode)
  let l:spliced  = mklib#map#splice(l:map)

  " only unplug one-literal maps
  if len(l:spliced.literal) == 1 && l:spliced.len() == 1
    " normalise the <Plug> code case for the comparison
    let l:map_rhs = substitute(l:map_rhs, '^\c<plug>', '<Plug>', '')

    " look for matching <Plug> maps
    if mklib#collection#has_value(l:plugmaps, l:map_rhs)
      let l:map     = mklib#map#unplug(maparg(l:map_rhs, l:map_mode, 0, 1))
      let l:map.lhs = get(a:map, 'lhs', '')
      return mklib#map#heuristics(l:map)
    endif
  endif
  return l:map
endfunction " }}}

" Splice {map}'s RHS into expressions and literals:
" @signature:  mklib#map#splice({map:Dictionary})
" @returns:    a Dictionary with the keys 'expr' and 'literal', each item
"              a Dictionary of matches keyed by index in the RHS,
"              and the same member functions as mklib#string#splice()
function! mklib#map#splice(map) abort " {{{
  if get(a:map, 'expr', 0)
    " match literals in <expr> maps
    let l:pattern = '''\@<!''.\{-}''\@<!''\|\\\@<!".\{-}\\\@<!"'
    let l:target  = 'literal'
  else
    " match register expressions in non-<expr> maps
    let l:pattern = '<[Cc]-[Rr]>=.\{-}<[Cc][Rr]>'
    let l:target  = 'expr'
  endif
  let l:tegrat  = l:target == 'expr' ? 'literal' : 'expr'

  let l:return = mklib#string#splice(get(a:map, 'rhs', ''), l:pattern)
  let l:return[l:target] = l:return.matching
  let l:return[l:tegrat] = l:return.rest
  unlet l:return.matching
  unlet l:return.rest

  return l:return
endfunction " }}}

" Return a copy of {map} with {key} trimmed from {map}.rhs
" with trimming happening at head or tail depending on {trailing}:
" @signature:  mklib#map#trimkey({key:String}, {map:Dictionary}[, {trailing:Number}])
" @returns:    a copy of {map} with {map.rhs} trimmed of {key}
" @exceptions: E605 if {key} is empty
" @notes:      only trims the key in literal parts of maps
function!mklib#map#trimkey(key, map, trailing) abort " {{{
  if empty(a:key)
    throw "Cannot trim an empty key: ".string(a:key)
  endif

  " target only literals
  let l:spliced    = mklib#map#splice(a:map)
  if !a:trailing && has_key(l:spliced.literal, 0)
    let l:target   = 0
  elseif a:trailing
    let l:last_key = l:spliced.keys()[-1]
    let l:target   = has_key(l:spliced.literal, l:last_key) ? l:last_key : -1
  else
    let l:target   = -1
  endif

  " trim '"\<Key>"' in expression literals, else '<Key>'
  " - leave quotes in expr literals alone for expr integrity
  " - compare <Key> (and only that!) without case sensitivity
  if l:target > -1
    let l:key  = '\C'.mklib#map#keys2pattern(a:key)
    let l:seek = get(a:map, 'expr', 0) ?
    \ a:trailing ? '\\'.l:key.'\%("\_$\)\@=' : '\%(\_^"\)\@<=\\'.l:key :
    \ a:trailing ? l:key.'$' : '^'.l:key
    let l:spliced.literal[l:target] = substitute(l:spliced.literal[l:target], l:seek, '', '')
  endif

  let l:map     = deepcopy(a:map)
  let l:map.rhs = l:spliced.join()
  return l:map
endfunction " }}}

" Create a map from {map}:
" @signature:  mklib#map#set({map:Dictionary})
" @returns:    1 if the map was successfully created, 0 otherwise
" @exceptions: E605 if {map.lhs} or {map.rhs} are empty
function! mklib#map#set(map) abort " {{{
  let l:to_set     = deepcopy(a:map)
  let l:to_set.lhs = mklib#string#trim(get(l:to_set, 'lhs', ''))
  let l:to_set.rhs = mklib#string#trim(get(l:to_set, 'rhs', ''))
  if empty(l:to_set.lhs) || empty(l:to_set.rhs)
    throw "Cannot set a map with an empty LHS or RHS: ".string(a:map)
  endif

  " generate command
  let l:cmd      = mklib#map#cmd4mode(get(l:to_set, 'noremap', 0) ? 'noremap' : 'map', get(l:to_set, 'mode', ''))
  let l:map_opts = ['buffer', 'nowait', 'silent', 'special', 'script', 'expr', 'unique']
  let l:cmd_opts = join(
  \   filter(
  \     map(l:map_opts, 'get(l:to_set, v:val, 0) == 1 ? "<".v:val.">" : ""'),
  \     '!empty(v:val)'
  \   ), ''
  \ )

  " cleanup
  if has_key(l:to_set, 'sid')
    " ensure SID maps are correct if a map.sid is passed
    let l:to_set.rhs = substitute(l:to_set.rhs,  '<SID>', '<SNR>'.l:to_set.sid.'_', 'g')
    " for #exists check, as the resulting SID from #set is that of this script,
    " but that is not accessible (<sfile> is the calling function):
    unlet l:to_set.sid
  endif

  silent execute l:cmd l:cmd_opts l:to_set.lhs l:to_set.rhs
  return mklib#map#exists(l:to_set.lhs, l:to_set)
endfunction " }}}

" Unset the map matching {map}:
" @signature:  mklib#map#unset({map:Dictionary})
" @returns:    1 if the map was unmapped, 0 otherwise
" @exceptions: E605 if {map.lhs} is empty
" @notes:      also returns 1 if there was no map to unmap
function! mklib#map#unset(map) abort " {{{
  let l:map_lhs = get(a:map, 'lhs', '')
  if empty(l:map_lhs)
    throw "Cannot unset a map without a LHS: ".string(a:map)
  endif
  if mklib#map#exists(l:map_lhs, a:map)
    execute mklib#map#cmd4mode('unmap', get(a:map, 'mode', '')) l:map_lhs
    return !mklib#map#exists(l:map_lhs, a:map)
  endif
  return 1
endfunction " }}}

" Merge two maps by creating a new <Plug> or <SID> for {child_map} and
" substituting that map's LHS for {parent_map.lhs} in {parent_map.rhs}:
" @signature:  mklib#map#merge({parent_map:Dictionary}, {child_map:Dictionary})
" @returns:    1 if the merge succeeded, 0 otherwise
" @exceptions: E605 if one of {parent_map}'s or {child_map}'s LHS or RHS is empty
" @notes:      <Plug> / <SID> maps are called '({parent_map.lhs}PreMerge_[num])',
"              with 'num' incremented from 0
function! mklib#map#merge(parent_map, child_map) abort  " {{{
  let l:parent     = deepcopy(a:parent_map)
  let l:parent.lhs = get(l:parent, 'lhs', '')
  let l:parent.rhs = get(l:parent, 'rhs', '')
  let l:child      = deepcopy(a:child_map)
  let l:child.rhs  = get(l:child, 'rhs', '')
  let l:child.lhs  = get(l:child, 'lhs', '')
  if empty(l:parent.lhs) || empty(l:parent.rhs) || empty(l:child.lhs) || empty(l:child.rhs)
    throw "LHS or RHS empty in either parent, child, or both!"
  endif

  " merging strategy conditional parameters
  let l:child_lhs_pattern = '\C'.mklib#map#keys2pattern(l:child.lhs)
  let l:parent_spliced    = mklib#map#splice(l:parent)
  let l:insertable        = len(
  \   filter(l:parent_spliced.literal, 'match(v:val, l:child_lhs_pattern) > -1')
  \ ) > 0
  let l:parent.expr       = get(l:parent, 'expr', 0)

  " guard against non-mergeable mappings
  if !l:insertable && l:parent.expr
    echomsg "Map" string(l:parent) "is an <expr> map whose RHS"
    \ "does not contain the child LHS" string(l:child.lhs) "; merge canceled!"
    return 0
  endif

  " extract implicitly noremap'ed {key} and try to unplug
  let l:delegate  = mklib#map#unplug(l:child)
  if !get(l:child, 'noremap', 0)
    let l:trimmed = mklib#map#trimkey(l:parent.lhs, l:delegate, 0)
    if l:trimmed.rhs != l:delegate.rhs
      let l:trimmed_key = l:parent.lhs
      let l:delegate    = mklib#map#unplug(l:trimmed)
    endif
  endif

  " generate delegate name
  let l:del_nr   = 0
  let l:del_map  = mklib#map#keys2normal(l:parent.lhs)
  let l:del_name = '('.l:del_map.'_PreMerge_'.l:del_nr.')'

  " strategies for child map delegation:
  " - parent is (re)map: create a <Plug> plug map
  " - parent is noremap: create a <SID> plug map, set parent to <script>
  let l:parent.script  = get(l:parent, 'noremap', 0) || get(l:parent, 'script', 0)
  let l:delegate.lhs   = (l:parent.script ? '<SID>' : '<Plug>').l:del_name
  while !empty(maparg(substitute(l:delegate.lhs, '^<SID>', '<SNR>'.s:SID().'_', ''), get(l:delegate, 'mode', '')))
    let l:del_nr      += 1
    let l:delegate.lhs = substitute(l:delegate.lhs, '_\zs'.l:del_nr-1.'\ze)$', l:del_nr, '')
  endwhile

  " guard against unsuccessful delegate map creation
  if !mklib#map#set(l:delegate)
    echomsg "Unable to create delegate map:" string(l:delegate) "; merge canceled!"
    return 0
  endif

  " strategies for map merging:
  " - parent RHS contains child LHS: insert delegate LHS into the RHS
  " - parent RHS does not contain child LHS:
  "   - if parent is not an <expr> map, append delegate LHS to parent RHS
  "   - if parent is an <expr> map, cancel merging (by guard farther up)
  let l:insert = get(l:, 'trimmed_key', '').l:delegate.lhs
  if l:insertable
    call map(l:parent_spliced.literal, 'substitute(v:val, l:child_lhs_pattern, l:insert, ''g'')')
    let l:parent.rhs = l:parent_spliced.join()
  elseif !l:parent.expr
    let l:parent.rhs .= l:insert
  else
    throw "Library developer f***ed up: you should never see this."
  endif
  return mklib#map#set(l:parent)
endfunction " }}}

" Create {map}, making it parent to an eventual pre-existing map:
" @signature:  mklib#map#unshift({map:Dictionary})
" @returns:    1 if the map was created or merged successfully, else 0
" @exceptions: E605 if {map.lhs} is empty
function! mklib#map#unshift(map) abort " {{{
  return s:shiftunshift(a:map, 'unshift')
endfunction " }}}

" Create {map}, making it child to an eventual pre-existing map:
" @signature:  mklib#map#shift({map:Dictionary})
" @returns:    1 if the map was created or merged successfully, else 0
" @exceptions: E605 if {map.lhs} is empty
function! mklib#map#shift(map) abort " {{{
  return s:shiftunshift(a:map, 'shift')
endfunction " }}}

" Return a valid map command string for the given mode (see :h map):
" @signature:  mklib#map#cmd4mode({cmd:String}, {mode:String})
" @returns:    the map command String
" @exceptions: E605 if an invalid {cmd} or {mode} is passed
" @notes:      valid {mode} chars are those returned by maparg()
"              with the dict option (see :h maparg())
function! mklib#map#cmd4mode(cmd, mode) abort " {{{
  " guard against invalid commands and modes
  let l:cmds  = ['map', 'unmap', 'noremap', 'mapclear']
  let l:modes = ['n', 'v', 'o', 'i', 'c', 's', 'x', 'l', '', ' ', '!']
  if !mklib#collection#has_value(l:cmds, a:cmd)
    throw 'Not a valid map command: '.string(a:cmd)
  elseif !mklib#collection#has_value(l:modes, a:mode)
    throw 'Not a valid map mode: '.string(a:mode)
  endif

  " build command proper
  let l:mode = a:mode == ' ' ? '' : a:mode
  return l:mode ==# '!' ? a:cmd.'!' : l:mode.a:cmd
endfunction " }}}

" Create a pattern where '<Key>' codes are case independent:
" @signature:  mklib#map#keys2pattern({string:String})
" @returns:    a pattern String
" @examples:   '<C-k>'      => '[Cc][-][Kk]'
"              'FooBar<CR>' => 'FooBar<[Cc][Rr]>'
function! mklib#map#keys2pattern(string) abort " {{{
  let l:spliced = mklib#string#splice(a:string, '<\zs.\{-}\ze>')
  for l:key in keys(l:spliced.matching)
    let l:spliced.matching[l:key] = mklib#string#uncase(l:spliced.matching[l:key])
  endfor
  return l:spliced.join()
endfunction " }}}

" Normalize all key codes to their canonical case:
" @signature:  mklib#map#keys2normal({string:String})
" @returns:    a String with all key codes normalized
" @examples:   '<c-k>'      => '<C-K>'
"              '<s-cr>r'     => '<S-CR>r'
"              '<pagedown>u' => '<PageDown>u'
function! mklib#map#keys2normal(string) abort " {{{
  let l:fixcase = ['BS', 'CR', 'NL', 'PageUp', 'PageDown']
  let l:modcode = 'CDMS'
  let l:extract = '<\zs.\{-}\ze>'

  let l:spliced = mklib#string#splice(a:string, l:extract)
  for l:key in keys(l:spliced.matching)
    let l:string = l:spliced.matching[l:key]
    " strategies:
    " - modifier-key (i.e. 'C-k'): upcase modifier, recurse on key
    " - keys in l:fixcase: use literal entry
    " - all others: capitalize
    if l:string =~? '^['.l:modcode.']-.\+$'
      let l:matches = matchlist(l:string, '\c\(['.l:modcode.']-\)\(.\+\)', 0)
      let l:spliced.matching[l:key] = toupper(l:matches[1]).
      \ (
      \   len(l:matches[2]) > 1
      \   ? matchstr(mklib#map#keys2normal("<".l:matches[2].">"), l:extract)
      \   : toupper(l:matches[2])
      \ )
    else
      let l:fixcase_index = mklib#collection#match(l:fixcase, l:string, {'ignorecase':1, 'full':1})
      let l:spliced.matching[l:key] = l:fixcase_index > -1
      \ ? l:fixcase[l:fixcase_index]
      \ : mklib#string#capitalize(l:string)
    endif
  endfor

  return l:spliced.join()
endfunction " }}}

" Internal helper functions
" - mklib#map#[un]shift core {{{
function! s:shiftunshift(map, direction) abort
  let l:map_lhs  = get(a:map, 'lhs', '')
  if empty(l:map_lhs)
    throw "Cannot ".a:direction." a map without a LHS: ".string(l:map_lhs)
  endif

  let l:existing = mklib#map#get(l:map_lhs, get(a:map, 'mode', ''))
  if empty(l:existing)
    return mklib#map#set(a:map)
  elseif a:direction ==# 'unshift'
    return mklib#map#merge(a:map, l:existing)
  elseif a:direction ==# 'shift'
    return mklib#map#merge(l:existing, a:map)
  else
    throw "Library developer f***ed up: you should never see this."
  endif
endfunction
" }}}
" - retrieve script SID {{{
function! s:SID()
  return matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_SID$')
endfun " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=0:

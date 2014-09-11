" mklib.vim - another VimL non-standard library
" Maintainer: Martin Kopischke <http://martin.kopischke.net>
" License:    same as Vim (:h license)

" FILETYPE HANDLING LIBRARY
" @notes:      all {filetype} arguments can be simple ('vim')
"              or composite ('c.doxygen') filetype Strings

" Set the current buffer's &filetype to {filetype},
" but only if it is not set to contain {filetype} already:
" @signature:  mklib#filetype#set({filetype:String})
" @returns:    the current buffer's &filetype String
function! mklib#filetype#set(filetype) abort " {{{
  if !mklib#filetype#contains(a:filetype)
    let &filetype = a:filetype
  endif
  return &filetype
endfunction " }}}

" Add {filetype} to the current buffer's &filetype:
" @signature:  mklib#filetype#add({filetype:String})
" @returns:    the current buffer's &filetype String
function! mklib#filetype#add(filetype) abort " {{{
  for l:filetype in mklib#filetype#types(a:filetype)
    if !mklib#filetype#contains(a:filetype)
      let &filetype = join(add(mklib#filetype#types(), a:filetype), '.')
    endif
  endfor
  return &filetype
endfunction " }}}

" Remove {filetype} from the current buffer's &filetype:
" @signature:  mklib#filetype#remove({filetype:String})
" @returns:    the current buffer's &filetype String
" @notes:      composite filetypes are only removed if all parts are present
function! mklib#filetype#remove(filetype) abort " {{{
  if mklib#filetype#contains(a:filetype)
    let &filetype = join(filter(mklib#filetype#types(), 'v:val !=# a:filetype'), '.')
  endif
  return &filetype
endfunction " }}}

" List all filetype codes in {filetype}:
" (in the current buffer's &filetype if omitted)
" @signature:  mklib#filetype#types([{fileytpe:String}])
" @returns:    a List of filetype String codes
function! mklib#filetype#types(...) abort " {{{
  return split(get(a:, 1, &filetype), '\V.')
endfunction " }}}

" Check if the current buffer's &filetype contains {filetype}:
" @signature:  mklib#filetype#contains({filetype:String})
" @returns:    a boolean Number (1/0)
function! mklib#filetype#contains(filetype) abort " {{{
  let l:wanted = mklib#filetype#types(a:filetype)
  let l:found  = filter(mklib#filetype#types(), 'mklib#collection#has_value(l:wanted, v:val)')
  return len(l:wanted) == len(l:found)
endfunction " }}}

" vim:set sw=2 sts=2 ts=8 et fdm=marker fdo+=jump fdl=0:

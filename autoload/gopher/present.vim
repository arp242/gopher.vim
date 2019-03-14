" present.vim: Implement support for go present slides.

" Jump to the next or previous section.
"
" mode can be 'n', 'o', or 'v' for normal, operator-pending, or visual mode.
" dir can be 'next' or 'prev'.
fun! gopher#present#jump(mode, dir) abort
  " Get motion count; done here as some commands later on will reset it.
  " -1 because the index starts from 0 in motion.
  let l:count = v:count1

  " Set context mark so user can jump back with '' or ``.
  normal! m'

  " Start visual selection or re-select previously selected.
  if a:mode is# 'v'
    normal! gv
  endif

  let l:save = winsaveview()
  for l:i in range(l:count)
    let l:loc = search('^\* ', 'W' . (a:dir is# 'prev' ? 'b' : ''))

    if l:loc > 0
      continue
    endif

    " Jump to top or bottom of file if we're at the first or last declaration.
    if l:i is l:count - 1
      exe 'keepjumps normal! ' . (a:dir is# 'next' ? 'G' : 'gg')
    else
      call winrestview(l:save)
    endif
    return
  endfor
endfun

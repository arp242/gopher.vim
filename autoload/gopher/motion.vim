" motion.vim: Implement motions and text objects.

" Jump to the next or previous top-level declaration.
"
" mode can be 'n', 'o', or 'v' for normal, operator-pending, or visual mode.
" dir can be 'next' or 'prev'.
fun! gopher#motion#jump(mode, dir) abort
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
    let l:loc = search('\v^(func|type|var|const|import)', 'W' . (a:dir is# 'prev' ? 'b' : ''))

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

" Select current comment block.
"
" mode can be 'a' or 'i', for the 'ac' and 'ic' variants.
fun! gopher#motion#comment(mode) abort
  let [l:fname, l:tmp] = gopher#system#tmpmod()

  try
    let l:cmd = ['motion', '-format', 'json',
          \ '-file',   l:fname,
          \ '-offset', gopher#buf#cursor(),
          \ '-mode',   'comment',
          \ ]

    let [l:out, l:err] = gopher#system#tool(l:cmd)
    if l:err
      return gopher#error(l:out)
    endif
  finally
    if l:tmp
      call delete(l:tmp)
    endif
  endtry

  try
    let l:loc = json_decode(l:out)
  catch
    return gopher#error(l:out)
  endtry
  if !has_key(l:loc, 'comment')
    return gopher#error(get(l:loc, 'err', l:out))
  endif

  let l:info = l:loc.comment
  call cursor(l:info.startLine, l:info.startCol)

  " Adjust cursor to exclude start comment markers. Try to be a little bit
  " clever when using multi-line '/*' markers.
  if a:mode is# 'i'
    " Trim whitespace so matching below works correctly.
    let l:line = substitute(getline('.'), '\v^\s*(.{-})\s*$', '\1', '')

    " //text
    if l:line[:2] is# '// '
      call cursor(l:info.startLine, l:info.startCol + 3)
    " // text
    elseif l:line[:1] is# '//'
      call cursor(l:info.startLine, l:info.startCol + 2)
    " /*
    " text
    elseif l:line =~# '^/\* *$'
      call cursor(l:info.startLine + 1, 0)
      " /*
      "  * text
      if getline('.')[:2] is# ' * '
        call cursor(l:info.startLine + 1, 4)
      " /*
      "  *text
      elseif getline('.')[:1] is# ' *'
        call cursor(l:info.startLine + 1, 3)
      endif
    " /* text
    elseif l:line[:2] is# '/* '
      call cursor(l:info.startLine, l:info.startCol + 3)
    " /*text
    elseif l:line[:1] is# '/*'
      call cursor(l:info.startLine, l:info.startCol + 2)
    endif
  endif

  normal! v

  " Exclude trailing newline.
  if a:mode is# 'i'
    let l:info.endCol -= 1
  endif

  call cursor(l:info.endLine, l:info.endCol)

  " Exclude trailing '*/'.
  if a:mode is# 'i'
    let l:line = getline('.')
    " text
    " */
    if l:line =~# '^ *\*/$'
      call cursor(l:info.endLine - 1, len(getline(l:info.endLine - 1)))
    " text */
    elseif l:line[-3:] is# ' */'
      call cursor(l:info.endLine, l:info.endCol - 3)
    " text*/
    elseif l:line[-2:] is# '*/'
      call cursor(l:info.endLine, l:info.endCol - 2)
    endif
  endif
endfun

" Select the current function.
"
" mode can be 'a' or 'i', for the 'af' and 'if' variants.
fun! gopher#motion#function(mode) abort
  let [l:fname, l:tmp] = gopher#system#tmpmod()

  try
    let l:cmd = ['motion', '-mode', 'enclosing', '-parse-comments',
          \ '-file',   l:fname,
          \ '-offset', gopher#buf#cursor(),
          \ '-format', 'vim',
          \ ]

    let [l:out, l:err] = gopher#system#tool(l:cmd)
    if l:err
      return gopher#error(l:out)
    endif
  finally
    if l:tmp
      call delete(l:tmp)
    endif
  endtry

  try
    let l:loc = json_decode(l:out)
  catch
    return gopher#error(l:out)
  endtry
  if !has_key(l:loc, 'comment')
    return gopher#error(get(l:loc, 'err', l:out))
  endif

  let l:info = l:loc.fn

  if a:mode is# 'a'
    " Anonymous functions don't have a doc comment.
    if has_key(l:info, 'doc')
      call cursor(l:info.doc.line, l:info.doc.col)
    elseif l:info['sig']['name'] is# ''
      " one liner anonymous functions
      if l:info.lbrace.line is l:info.rbrace.line
        " jump to first nonblack char, to get the correct column
        call cursor(l:info.lbrace.line, 0 )
        normal! ^
        call cursor(l:info.func.line, col('.'))
      else
        call cursor(l:info.func.line, l:info.rbrace.col)
      endif
    else
      call cursor(l:info.func.line, l:info.func.col)
    endif

    normal! v
    call cursor(l:info.rbrace.line, l:info.rbrace.col)
    return
  elseif a:mode is# 'i'
    " Select only that portion if the function is a one liner.
    if l:info.lbrace.line is l:info.rbrace.line
      call cursor(l:info.lbrace.line, l:info.lbrace.col + 1)
      normal! v
      call cursor(l:info.rbrace.line, l:info.rbrace.col - 1)
      return
    endif

    call cursor(l:info.lbrace.line + 1, 1)
    normal! V
    call cursor(l:info.rbrace.line - 1, 1)
  endif
endfun

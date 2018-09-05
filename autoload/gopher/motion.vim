" Jump to the next or previous function.
"
" mode can be 'n', 'o', or 'v' for normal, operator-pending, or visual mode.
" dir can be 'next' or 'prev'.
"
" TODO: I think it would make more sense to jump to next top-level declaration
" (func, type, var, etc.)
fun! gopher#motion#jump(mode, dir) abort
  " Get motion count; done here as some commands later on will reset it.
  " -1 because the index starts from 0 in motion.
  let l:cnt = v:count1 - 1

  " Set context mark so we can jump back with '' or ``.
  normal! m'

  " Either start visual selection, or re-select previously selected visual
  " content and continue from there.
  if a:mode is# 'v'
    normal! gv
  endif

  let l:loc = gopher#motion#location(a:dir, l:cnt)
  if l:loc is 0
    return
  endif

  " Jump to top or bottom of file if we're at the first or last function.
  if type(l:loc) is v:t_dict && get(l:loc, 'err', '') is? 'no functions found'
    exe 'keepjumps normal! ' . (a:dir is# 'next' ? 'G' : 'gg')
    return
  endif

  keepjumps call cursor(l:loc.fn.func.line, 1)
endfun

" Get the location of the previous or next function.
"
" TODO: Should work for other top-level declarations, too.
fun! gopher#motion#location(dir, cnt) abort
  let [l:fname, l:tmp] = gopher#system#tmpmod()

  try
    let l:cmd = ['motion', '-format', 'vim',
          \ '-file',   l:fname,
          \ '-offset', gopher#internal#cursor_offset(),
          \ '-shift',  a:cnt,
          \ '-mode',   a:dir,
          \ ]

    let [l:out, l:err] = gopher#system#tool(l:cmd)
    if l:err
      call gopher#internal#error(out)
      return
    endif
  finally
    if l:tmp isnot# ''
      call delete(l:tmp)
    endif
  endtry

  let l:loc = json_decode(l:out)
  if type(l:loc) isnot v:t_dict
    call gopher#internal#error(l:out)
    return 0
  endif

  return l:loc
endfun

" Select current comment block.
fun! gopher#motion#comment(mode) abort
  let [l:fname, l:tmp] = gopher#system#tmpmod()

  try
    let l:cmd = ['motion', '-format', 'json',
          \ '-file',   l:fname,
          \ '-offset', gopher#internal#cursor_offset(),
          \ '-mode',   'comment',
          \ ]

    let [l:out, l:err] = gopher#system#tool(l:cmd)
    if l:err
      call gopher#internal#error(l:out)
      return
    endif
  finally
    if l:tmp isnot# ''
      call delete(l:tmp)
    endif
  endtry

  let l:loc = json_decode(l:out)
  if type(l:loc) isnot v:t_dict || !has_key(l:loc, 'comment')
    call gopher#internal#error(l:out)
    return
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

" Select a function in visual mode.
function! gopher#motion#function(mode) abort
  let [l:fname, l:tmp] = gopher#system#tmpmod()

  try
    let l:cmd = ['motion', '-mode', 'enclosing', '-parse-comments',
          \ '-file',   l:fname,
          \ '-offset', gopher#internal#cursor_offset(),
          \ '-format', 'vim',
          \ ]

    let [l:out, l:err] = gopher#system#tool(l:cmd)
    if l:err
      call gopher#internal#error(out)
      return
    endif
  finally
    if l:tmp isnot? ''
      call delete(l:tmp)
    endif
  endtry

  let l:loc = json_decode(l:out)
  if type(l:loc) isnot v:t_dict || !has_key(l:loc, 'fn')
    call gopher#internal#error(l:out)
    return
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

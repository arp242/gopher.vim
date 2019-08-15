" frob.vim: Modify Go code.

scriptencoding utf-8

" Run the :GoFrob command.
fun! gopher#frob#cmd(...) abort
  if a:0 is 0
    return gopher#frob#popup()
  endif

  if a:1 is# 'implement' && a:0 < 2
    return gopher#error('must specify at least one interface name')
  endif

  call s:run_cmd(0, a:1, a:000[1:])
endfun

" Complete the mappings people can choose and interfaces for 'implement'.
fun! gopher#frob#complete(lead, cmdline, cursor) abort
  if getcmdtype() is# '@' || a:cmdline[:16] is# 'GoFrob implement '
    return gopher#compl#filter(a:lead, s:find_interface(a:lead))
  endif
  return gopher#compl#filter(a:lead, ['if', 'return', 'error', 'implement'])
endfun

" Find all interfaces starting with lead.
"
" Before the dot we complete a package; for example on 'i' it completes:
"   [image, image/color, .., io, io/ioutil]
"
" After the dot it completes interfaces for that package; for 'io.':
"   [io.ByteReader, .., io.WriterTo]
fun! s:find_interface(lead) abort
  if a:lead is# '' || a:lead !~# '^\h\w.*\.\%(\h\w*\)\=$'
    return gopher#pkg#list_importable()
  endif

  let l:pkg = split(a:lead, '\.', 1)
  let [l:iface, l:pkg] = [l:pkg[-1], join(l:pkg[:-2], '.')]
  return map(filter(gopher#pkg#list_interfaces(l:pkg),
        \ {_, v -> strpart(l:v, 0, len(l:iface)) is# l:iface}),
        \ {_, v -> l:pkg . '.' . l:v})
endfun

" Implement methods for an interface.
fun! gopher#frob#implement(iface) abort
  try
    let l:save = winsaveview()

    let l:type = split(getline('.'), ' ')
    if len(l:type) < 3 || l:type[0] isnot# 'type'
      return gopher#error('no type definition on this line')
    endif
    let l:type = l:type[1]
    let l:recv = tolower(l:type)[0]

    let [l:out, l:err] = gopher#system#tool(['impl',
          \ '-dir', expand('%:p:h'),
          \ printf('%s *%s', l:recv, l:type), a:iface])
    if l:err
      return gopher#error(l:out)
    endif

    " TODO(impl): everything beyond here is hacky. Should improve impl tool.

    " Get just the function signatures.
    let l:out =  map(split(l:out, '}')[:-2], { _, v -> split(l:v, "\n")[0][:-3]})
    let l:existing = map(split(execute('g/func (\h\w* \*\h\w*) '), "\n"), { _, v -> v[:-3]})

    " Move to end of struct.
    call winrestview(l:save)
    if getline('.')[-9:] is# ' struct {'
      normal! $%
    endif

    for l:f in l:out
      " Filter out methods that already exist.
      let l:have = 0
      for l:e in l:existing
        if l:f is# l:e
          let l:have = 1
          break
        endif
      endfor

      if l:have
        continue
      end

      " Format to be a bit nicer.
      let l:comment = printf('// %s implements the %s interface.',
            \ matchstr(l:f, ') \k\+(')[2:-2], a:iface)
      call append('.', ['', l:comment, '//', '// TODO: implement', l:f . ' {', '', '}'])

      " Add return.
      normal! 6j
      call gopher#frob#ret(0)
      normal! >>6k
    endfor
  finally
    call winrestview(l:save)
  endtry
endfun

" Toggle between 'single-line' and 'normal' if checks:
"
"   err := e()
"   if err != nil {
"
" and:
"
"   if err := e(); err != nil {
"
" This works for all variables, not just error checks.
fun! gopher#frob#if() abort
  let l:line = getline('.')
  if match(l:line, 'if ') is -1
    " Try line below current one too.
    let l:line = getline(line('.') + 1)
    if match(l:line, 'if ') is -1
      return gopher#error('No if statement on current or next line')
    endif

    normal! j
  endif

  let l:line = substitute(l:line, '^\s*', '', '')
  let l:indent = repeat("\t", indent('.') / 4)

  " Convert 'if .. {' to 'if ..; err != nil {'.
  if match(l:line, ';') is -1
    let l:decl = substitute(getline(line('.') - 1), '^\s*', '', '')
    if match(l:decl, '=') is# -1
      return gopher#error('No variable declaration on the line above if')
    endif

    execute ':' . (line('.') - 1) . 'd _'
    call setline('.', printf('%sif %s; %s', l:indent, l:decl, trim(getline('.'))[3:]))
  " Convert 'if ..; err != nil {' to 'if .. {'.
  else
    let [l:prev_line, l:line] = split(l:line, '; ')
    let l:prev_line = substitute(l:prev_line, '^\s*', '', '')[3:]
    call setline('.', printf('%sif %s', l:indent, l:line))
    call append(line('.') - 1, printf('%s%s', l:indent, l:prev_line))
  endif
endfun

" Generate a return statement with zero values.
"
" If error is 1 it will return 'err' and surrounded in an 'if err != nil' check.
fun! gopher#frob#ret(error) abort
  let [l:out, l:err] = gopher#system#tool(
        \ ['gosodoff', '-pos=' . gopher#buf#cursor(), (a:error ? '-errcheck' : v:null)],
        \ gopher#buf#lines())
  if l:err
    return gopher#error(l:out)
  endif

  " Go up one line if the current line is blank (assume cursor is below 'err := ... ).
  if getline('.') =~# '^\s*$'
    delete _
    normal! k
  endif

  " Copy indent.
  let l:indent = matchstr(getline('.'), '^\s*')
  if l:indent is# ''
    let l:indent = matchstr(getline(line('.') - 1), '^\s*')
  endif

  call append('.', map(split(l:out, "\n"), {_, l -> l:indent . l:l}))

  normal! j^

  " Position cursor on 'err'.
  if a:error
    normal! j$b
  endif
endfun

let s:popup_items = [
      \ ['if',        'Toggle if style'],
      \ ['return',    'Add return'],
      \ ['error',     'Add return with if err != nil'],
      \ ['implement', 'Add interface methods'],
  \ ]

" key -> action mapping (reverse of g:gopher_map).
let s:map = {}

" Show a popup menu with mappings to choose from.
fun! gopher#frob#popup() abort
  " Makes s:map and desciption list.
  let l:items = []
  for l:item in s:popup_items
    let l:map = get(g:gopher_map, l:item[0], v:null)
    if l:map isnot v:null
      let s:map[l:map] = l:item[0]
      let l:items = add(l:items, printf('(%s) %s', l:map, l:item[1]))
    endif
  endfor

  " Fallback for older versions.
  if !exists('*popup_create') || !exists('*popup_close')
    echo join(map(items(s:map), {_, v-> printf('(%s) %s', v[0], v[1])}), ' | ')
    let l:char = nr2char(getchar())
    let l:c = get(s:map, l:char, 0)
    redraw  " Clear enter prompt
    if l:c is 0
      return gopher#error('invalid selection: %s', l:char)
    endif
    return s:run_cmd(0, l:c)
  endif

  let l:o = get(g:, 'gopher_popup', {})
  let l:CB = get(g:, 'Gopher_popup')
  if type(l:CB) is v:t_func
    let l:o = extend(l:o, l:CB())
  endif

  call popup_create(l:items, gopher#dict#merge({
        \ 'filter':          function('s:filter'),
        \ 'callback':        function('s:run_cmd'),
        \ 'mapping':         0,
        \ 'cursorline':      1,
        \ 'line':            'cursor+1',
        \ 'col':             'cursor',
        \ 'moved':           'WORD',
        \ 'title':           '─ gopher.vim',
        \ 'padding':         [0, 1, 0, 1],
        \ 'border':          [],
        \ 'borderchars':     ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
      \ }, l:o))
endfun

fun! s:filter(id, key) abort
  if a:key is# 'x' || a:key is# ''
    call popup_clear()
    return 1
  endif

  " No shortcut, pass to generic filter
  let l:action = get(s:map, a:key, -1)
  if l:action is -1
    return popup_filter_menu(a:id, a:key)
  endif

  call popup_close(a:id, l:action)
  return 1
endfun

fun! s:run_cmd(id, cmd, ...) abort
  " Fixes some problems with the popup menu's buffer still being open when we
  " start doing various operations (wrong text, infinite recursion, etc.)
  " TODO(popup): I think this is a Vim bug? Or am I using it wrong? Need to look
  " deeper.
  call popup_clear()

  let l:cmd = a:cmd
  if type(l:cmd) is v:t_number
    let l:cmd = s:popup_items[a:cmd - 1][0]
  endif

  if l:cmd is# 'if'
    call gopher#frob#if()
  elseif l:cmd is# 'return'
    call gopher#frob#ret(0)
  elseif l:cmd is# 'error'
    call gopher#frob#ret(1)
  elseif l:cmd is# 'implement'
    if a:0 is 0
      let l:in = [input('interface? ', '', 'customlist,gopher#frob#complete')]
    else
      let l:in = a:1
    endif

    for l:i in l:in
      call gopher#frob#implement(l:i)
    endfor
  elseif l:cmd isnot -1
    call gopher#error('unknown command: %s', l:cmd)
  endif
endfun

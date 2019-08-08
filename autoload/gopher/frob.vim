" frob.vim: Modify Go code.
"
" TODO: using stuff like 'normal! k' from the popup menu doesn't really work
" very well, so we use:
"
"    let l:pos = getpos('.')
"    let l:pos[1] -= 1
"    call setpos('.', l:pos)
"
" I'm not sure if this is a Vim bug/issue or expected.

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
    return filter(s:find_interface(a:lead),
          \ {_, v -> strpart(l:v, 0, len(a:lead)) is# a:lead})
  endif

  return filter(['if', 'return', 'error', 'implement'],
        \ {_, v -> strpart(l:v, 0, len(a:lead)) is# a:lead})
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
    return uniq(sort(gopher#pkg#list_std() + gopher#pkg#list_deps()))
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
      " TODO: doesn't account for type ( .. ) blocks.
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

    " TODO: everything beyond here is hacky. Should improve impl tool.

    " Get just the function signatures.
    let l:out =  map(split(l:out, '}')[:-2], { _, v -> split(l:v, "\n")[0][:-3]})
    let l:existing = map(split(execute('g/func (\w\k* \*\w\k*) '), "\n"), { _, v -> v[:-3]})

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

    "normal! j
    let l:pos = getpos('.')
    let l:pos[1] += 1
    call setpos('.', l:pos)
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
        \ ['gosodoff', '-pos=' . gopher#buf#cursor(), (a:error ? '-errcheck' : v:none)],
        \ gopher#buf#lines())
  if l:err
    return gopher#error(l:out)
  endif

  " Go up one line if the current line is blank (assume cursor is below 'err := ... ').
  if getline('.') =~# '^\s*$'
    "delete _
    "normal! k
    let l:pos = getpos('.')
    let l:pos[1] -= 1
    call setpos('.', l:pos)
  endif

  " Copy indent.
  let l:indent = matchstr(getline('.'), '^\s*')
  if l:indent is# ''
    let l:indent = matchstr(getline(line('.') - 1), '^\s*')
  endif

  call append('.', map(split(l:out, "\n"), {_, l -> l:indent . l:l}))

  "normal! j^
  let l:pos = getpos('.')
  let l:pos[1] += 1
  call setpos('.', l:pos)

  if a:error
    " Position cursor on 'err'.
    "normal! j$b
    let l:pos[1] += 1
    call setpos('.', l:pos)
    let l:pos = getpos('.')

    if getline(line('.') + 1) =~# 'return$'
      call setpos('.', l:pos)
    else
      let l:pos[2] = col('$') - 3
      call setpos('.', l:pos)
    end
  endif
endfun

let s:desc = {
          \ 'if':        'Toggle if style',
          \ 'return':    'Add return',
          \ 'error':     'Add return with if err != nil',
          \ 'implement': 'Add interface methods',
      \ }

" key -> action mapping (reverse of g:gopher_map).
let s:map = {}

" Show a popup menu with mappings to choose from.
fun! gopher#frob#popup() abort
  " TODO: dict so order isn't stable.
  let l:items = []
  for [l:k, l:v] in items(g:gopher_map)
    if l:k[0] isnot# '_'
      let l:items = add(l:items, printf('(%s) %s', l:v, s:desc[l:k]))
      let s:map[l:v] = l:k
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

  " TODO: disabled for now as I can't figure out how to get selection to work.
        " \ 'cursorline':      1,
  call popup_create(l:items, gopher#dict#merge({
        \ 'filter':          function('s:filter'),
        \ 'callback':        function('s:run_cmd'),
        \ 'line':            'cursor+1',
        \ 'col':             'cursor',
        \ 'moved':           'WORD',
        \ 'title':           '─ gopher.vim',
        \ 'padding':         [0, 1, 0, 1],
        \ 'border':          [],
        \ 'borderchars':     ['─', '│', '─', '│', '┌', '┐', '┘', '└'],
      \ }, l:o))
endfun

" TODO: weird stuff happens when pressing mapping to open twice (;;). Not sure
" if we're doing it wrong or Vim bug.
fun! s:filter(id, key) abort
  if a:key is# "\n" || a:key is# "\r" || a:key is# ' ' || a:key is# "\t"
    " TODO: run selection; not entirely obvious how to do that
    "getbufline(a:id, 1)     -> always []
    "popup_getoptions(a:id)  -> not in here
    " popup_getpos(a:id))    -> idem

    return 1
  endif

  let l:action = get(s:map, a:key, 0)
  if l:action is 0
    " No shortcut, pass to generic filter
    " TODO: disabled for now as I can't figure out how to get selection to work.
    "return popup_filter_menu(a:id, a:key)
    return 0
  endif

  call popup_close(a:id, l:action)
  return 1
endfun

fun! s:run_cmd(id, cmd, ...) abort
  if a:cmd is# 'if'
    call gopher#frob#if()
  elseif a:cmd is# 'return'
    call gopher#frob#ret(0)
  elseif a:cmd is# 'error'
    call gopher#frob#ret(1)
  elseif a:cmd is# 'implement'
    if a:id > 0
      call popup_close(a:id)
    endif

    if a:0 is 0
      let l:in = [input('interface? ', '', 'customlist,gopher#frob#complete')]
    else
      let l:in = a:1
    endif

    for l:i in l:in
      call gopher#frob#implement(l:i)
    endfor
  elseif a:cmd isnot -1
    call gopher#error('unknown command: %s', a:cmd)
  endif
endfun

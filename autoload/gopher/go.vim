" go.vim: Utilities for working with Go files.

" Report if the current buffer is a Go test file.
fun! gopher#go#is_test() abort
  return expand('%')[-8:] is# '_test.go'
endfun

" Report if the current buffer is inside GOPATH.
fun! gopher#go#in_gopath() abort
  let [l:out, l:err] = gopher#system#run(['go', 'env', 'GOPATH'])
  if l:err
    return gopher#error(l:out)
  endif

  let l:path = expand('%:p')
  for l:gopath in split(l:out, gopher#system#pathsep())
    if gopher#str#has_prefix(l:path, l:out)
      return 1
    endif
  endfor

  return 0
endfun

" Get the Go module name, or -1 if there is none.
fun! gopher#go#module() abort
  let l:wd = getcwd()

  try
    call chdir(expand('%:h'))
    let [l:out, l:err] = gopher#system#run(['go', 'list', '-m', '-f',
          \ "{{.Path}}\x01{{.Dir}}"])
    if l:err
      return [-1, -1]
    endif
    let l:s = split(l:out, "\x01")
    if len(l:s) isnot# 2
      return [-1, -1]
    endif
    return l:s
  finally
    call chdir(l:wd)
  endtry
endfun

" Strip version (/v2, /v3 etc.) from a package name.
"
"   example.com/pkg/v3 → example.com/pkg
"   example.com/pkg    → example.com/pkg
fun! gopher#go#remove_version(pkg) abort
  return substitute(a:pkg, '/v\d\+$', '', '')
endfun

" Get the package path for the file in the current buffer.
fun! gopher#go#package() abort
  let [l:out, l:err] = gopher#system#run(['go', 'list', './' . expand('%:h')])
  if l:err || l:out[0] is# '_'
    if l:out[0] is# '_' || gopher#str#has_suffix(l:out, 'cannot import absolute path')
      let l:out = 'cannot determine module path (outside GOPATH, no go.mod)'
    endif
    call gopher#error(l:out)
    return ''
  endif

  return l:out
endfun

" Get path to file in current buffer as package/path/file.go
fun! gopher#go#packagepath() abort
  return gopher#go#package() . '/' . expand('%:t')
endfun

let s:go_commands = ['go', 'bug', 'build', 'clean', 'doc', 'env', 'fix', 'fmt',
                   \ 'generate', 'get', 'install', 'list', 'mod', 'run', 'test',
                   \ 'tool', 'version', 'vet']

" Add b:gopher_build_tags or g:gopher_build_tags to the flag_list; will be
" merged with existing tags (if any).
fun! gopher#go#add_build_tags(flag_list) abort
  if get(g:, 'gopher_build_tags', []) == []
    return a:flag_list
  endif

  if type(a:flag_list) isnot v:t_list
    call gopher#error('add_build_tags: not a list: %s', a:flag_list)
    return a:flag_list
  endif

  let l:tags = gopher#bufsetting('gopher_build_tags', [])

  let l:last_flag = 0
  for l:i in range(len(a:flag_list))
    if a:flag_list[l:i][0] is# '-' || index(s:go_commands, a:flag_list[l:i]) > -1
      let l:last_flag = l:i
    endif

    if a:flag_list[l:i] is# '-tags'
      let l:tags = uniq(split(trim(a:flag_list[l:i+1], "\"'"), ',') + l:tags)
      return a:flag_list[:l:i]
            \ + ['"' . join(l:tags, ' ') . '"']
            \ +  a:flag_list[l:i+2:]
    endif
  endfor

  return a:flag_list[:l:last_flag]
        \ + ['-tags', '"' . join(l:tags, ',') . '"']
        \ + a:flag_list[l:last_flag+1:]
endfun

" Find the build tags for the current buffer; returns a list (or empty list if
" there are none).
fun! gopher#go#find_build_tags() abort
  " https://golang.org/pkg/go/build/#hdr-Build_Constraints
  for l:i in range(1, line('$'))
    let l:line = getline(l:i)
    if l:line =~# '^// +build '
      return uniq(sort(gopher#list#flatten(map(split(l:line[10:], ' '), {_, v -> split(v, ',')}))))
    endif

    if l:line =~# '^package \f'
      return []
    endif
  endfor

  return []
endfun

" Set b:gopher_build_package to ./cmd/[module-name] if it exists.
fun! gopher#go#set_build_package() abort
  if &buftype isnot# '' || &filetype isnot# 'go'
    return
  endif

  if gopher#bufsetting('gopher_build_package', '') isnot ''
    return
  endif

  " TODO: maybe cache this a bit? Don't need to do it for every buffer in the
  " same directory.
  let [l:module, l:modpath] = gopher#go#module()
  if l:module is# -1
    return
  endif

  let l:name = fnamemodify(gopher#go#remove_version(l:module), ':t')
  let l:pkg  = l:module  . '/cmd/' . l:name
  let l:path = l:modpath . '/cmd/' . l:name

  " We're already in (possible a different) ./cmd/<name> subpackage: use this
  " one instead of clobbering ./cmd/other with ./cmd/main
  if gopher#str#has_prefix(bufname(''), 'cmd/')
    let b:gopher_build_package = l:module . '/' . fnamemodify(bufname(''), ':h')
    compiler go
    return
  endif

  if isdirectory(l:path) && get(b:, 'gopher_build_package', '') isnot# l:pkg
    let b:gopher_build_package = l:pkg
    compiler go
  endif
endfun

" Set b:gopher_build_tags to the build tags in the current buffer.
fun! gopher#go#set_build_tags() abort
  if &buftype isnot# '' || &filetype isnot# 'go'
    return
  endif

  " TODO: be even smarter about this: merge the g: and b: vars, and allow
  " setting a special '%BUFFER%' so you can both set tags from vimrc and merge
  " from file.
  if len(gopher#bufsetting('gopher_build_tags', '')) > 0
    return
  endif

  let l:tags = gopher#go#find_build_tags()
  if l:tags != get(b:, 'gopher_build_tags', [])
    let b:gopher_build_tags = l:tags
    compiler go
  endif
endfun

" Get the function name the cursor is in; the return value is a list where the
" first item is the full name and the second one is the full signature minus
" 'func':
"
"   func foo()                → ['foo', 'foo()']
"   func foo(x int) int       → ['foo', 'foo(x int) int']
"   func (t T) foo(x int) int → ['T.foo', '(t T) foo(x int) int']
"
" Returns ['', ''] if there is no function.
fun! gopher#go#current_function() abort
  if getline('.') =~# '^func'
    return s:line_to_fun()
  endif

  let l:save = winsaveview()
  try
    " Ensure we're in a function.
    " TODO: this can be faster by checking if the closing brace after [[ is
    " after the cursor line before the jump.
    let [l:fname, l:tmp] = gopher#system#tmpmod()
    let l:cmd = ['motion', '-mode', 'enclosing',
          \ '-file',   l:fname,
          \ '-offset', gopher#buf#cursor(),
          \ '-format', 'vim',
          \ ]
    let [l:out, l:err] = gopher#system#tool(l:cmd)
    if l:err
      return ['', '']
    endif
    try
      let l:loc = json_decode(l:out)
    catch
      return gopher#error(l:out)
    endtry
    if !has_key(l:loc, 'comment')
      return ['', '']
    endif

    " Jump to function declaration.
    call gopher#motion#jump('n', 'prev')
    if getline('.') !~# '^func'
      return ['', '']
    endif
    return s:line_to_fun()
  finally
    call winrestview(l:save)
  endtry
endfun

fun! s:line_to_fun() abort
  let l:sig = trim(getline('.')[4:-2])

  let l:name = l:sig
  if l:name[0] is# '('
    let l:name = l:name[stridx(l:name, ')') + 2:]
  endif
  let l:name = l:name[:stridx(l:name, '(') - 1]

  return [l:name, l:sig]
endfun

" Get the current test name as ['TestFoo'), or an empty list if the cursor isn't
" inside a test function.
"
" If a:run is non-0 it will return the name as ['-run', '^TestFoo$'], for
" passing to a 'go test' command.
fun! gopher#go#current_test(run) abort
  if !gopher#go#is_test()
    return []
  endif

  let l:f = gopher#go#current_function()[0]
  if l:f is# '' || l:f !~# '^Test'
    return []
  endif

  if a:run
    return ['-run', printf('^%s$', l:f)]
  endif
  return l:f
endfun

" Run the go compiler.
fun! gopher#go#run_install() abort
  silent! wa
  compiler go
  echo &l:makeprg
  silent make!
  redraw!
endfun

" Run go test for the current package.
fun! gopher#go#run_test() abort
  silent! wa
  compiler gotest
  echo &l:makeprg
  silent make!
  redraw!
endfun

" Run go test for the current function.
fun! gopher#go#run_test_current() abort
  silent! wa
  compiler gotest

  let l:t = gopher#system#join(gopher#go#current_test(1))
  echo &l:makeprg . ' ' . l:t
  exe 'silent make! ' . l:t
  redraw!
endfun

" Run lint tool for the current package.
fun! gopher#go#run_lint() abort
  silent! wa
  compiler golint
  echo &l:makeprg
  silent make!
  redraw!
endfun

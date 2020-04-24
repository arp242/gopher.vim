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
    let [l:out, l:err] = gopher#system#run(['go', 'list', '-m'])
    if l:err
      return -1
    endif
    return l:out
  finally
    call chdir(l:wd)
  endtry
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
endfun

" Set b:gopher_install_package to ./cmd/[module-name] if it exists.
fun! gopher#go#set_install_package() abort
  if gopher#bufsetting('gopher_install_package', '') isnot ''
    return
  endif

  let l:module = gopher#go#module()
  if l:module is# -1
    return
  endif

  " TODO: maybe cache this a bit? Don't need to do it for every buffer in the
  " same directory.
  let l:name = fnamemodify(l:module, ':t')
  let l:pkg = gopher#system#closest(l:name) . '/cmd/' . l:name
  if isdirectory(l:pkg) && get(b:, 'gopher_install_package', '') isnot# l:pkg
    let b:gopher_install_package = l:pkg
    compiler go
  endif
endfun

" Set b:gopher_build_tags to the build tags in the current buffer.
fun! gopher#go#set_build_tags() abort
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

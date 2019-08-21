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
  let [l:out, l:err] = gopher#system#run(['go', 'list', '-m'])
  if l:err
    return -1
  endif
  return l:out
endfun

" Get the package path for the file in the current buffer.
fun! gopher#go#package() abort
  let [l:out, l:err] = gopher#system#run(['go', 'list', expand('%:h')])
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

" Add g:gopher_build_tags to the flag_list; will be merged with existing tags
" (if any).
fun! gopher#go#add_build_tags(flag_list) abort
  if get(g:, 'gopher_build_tags', []) == []
    return a:flag_list
  endif

  if type(a:flag_list) isnot v:t_list
    call gopher#error('add_build_tags: not a list: %s', a:flag_list)
    return a:flag_list
  endif

  let l:last_flag = 0
  for l:i in range(len(a:flag_list))
    if a:flag_list[l:i][0] is# '-' || index(s:go_commands, a:flag_list[l:i]) > -1
      let l:last_flag = l:i
    endif

    if a:flag_list[l:i] is# '-tags'
      let l:tags = uniq(split(trim(a:flag_list[l:i+1], "\"'"), ' ') + g:gopher_build_tags)
      return a:flag_list[:l:i]
            \ + ['"' . join(l:tags, ' ') . '"']
            \ +  a:flag_list[l:i+2:]
    endif
  endfor

  return a:flag_list[:l:last_flag]
        \ + ['-tags', '"' . join(g:gopher_build_tags, ' ') . '"']
        \ + a:flag_list[l:last_flag+1:]
endfun

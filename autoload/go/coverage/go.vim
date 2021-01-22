" go.vim: Utilities for working with Go files.

" Get the Go module name, or -1 if there is none.
fun! go#coverage#go#module() abort
  let l:wd = getcwd()

  try
    call chdir(expand('%:h'))
    let [l:out, l:err] = go#coverage#system#run(['go', 'list', '-m', '-f',
          \ "{{.Path}}\x01{{.Dir}}"])
    if l:err
      return [-1, -1]
    endif
    let l:out_list = split(l:out, "\x01")
    if len(l:out_list) != 2
      return [-1, -1]
    endif
    return l:out_list
  finally
    call chdir(l:wd)
  endtry
endfun

" Get the package path for the file in the current buffer.
fun! go#coverage#go#package() abort
  let [l:out, l:err] = go#coverage#system#run(['go', 'list', './' . expand('%:h')])
  if l:err || l:out[0] is# '_'
    if l:out[0] is# '_' || go#coverage#str#has_suffix(l:out, 'cannot import absolute path')
      let l:out = 'cannot determine module path (outside GOPATH, no go.mod)'
    endif
    call go#coverage#msg#error(l:out)
    return ''
  endif

  return l:out
endfun

" Get path to file in current buffer as package/path/file.go
fun! go#coverage#go#packagepath() abort
  return go#coverage#go#package() . '/' . expand('%:t')
endfun

let s:go_commands = ['go', 'bug', 'build', 'clean', 'doc', 'env', 'fix', 'fmt',
                   \ 'generate', 'get', 'install', 'list', 'mod', 'run', 'test',
                   \ 'tool', 'version', 'vet']

" Add b:go_coverage_build_tags or g:go_coverage_build_tags to the flag_list; will be
" merged with existing tags (if any).
fun! go#coverage#go#add_build_tags(flag_list) abort
  if get(g:, 'go_coverage_build_tags', []) == []
    return a:flag_list
  endif

  if type(a:flag_list) isnot v:t_list
    call go#coverage#msg#error('add_build_tags: not a list: %s', a:flag_list)
    return a:flag_list
  endif

  let l:tags = go#coverage#bufsetting('go_coverage_build_tags', [])

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
fun! go#coverage#go#find_build_tags() abort
  " https://golang.org/pkg/go/build/#hdr-Build_Constraints
  for l:i in range(1, line('$'))
    let l:line = getline(l:i)
    if l:line =~# '^// +build '
      return uniq(sort(go#coverage#list#flatten(map(split(l:line[10:], ' '), {_, v -> split(v, ',')}))))
    endif

    if l:line =~# '^package \f'
      return []
    endif
  endfor

  return []
endfun

" Set b:go_coverage_build_package to ./cmd/[module-name] if it exists.
fun! go#coverage#go#set_build_package() abort
  if &buftype isnot# '' || &filetype isnot# 'go'
    return
  endif

  if go#coverage#bufsetting('go_coverage_build_package', '') isnot ''
    return
  endif

  " TODO: maybe cache this a bit? Don't need to do it for every buffer in the
  " same directory.
  let [l:module, l:modpath] = go#coverage#go#module()
  if l:module is# -1
    return
  endif

  let l:name = fnamemodify(l:module, ':t')
  let l:pkg  = l:module  . '/cmd/' . l:name
  let l:path = l:modpath . '/cmd/' . l:name

  " We're already in (possible a different) ./cmd/<name> subpackage: use this
  " one instead of clobbering ./cmd/other with ./cmd/main
  if go#coverage#str#has_prefix(bufname(''), 'cmd/')
    let b:go_coverage_build_package = l:module . '/' . fnamemodify(bufname(''), ':h')
    compiler go
    return
  endif

  if isdirectory(l:path) && get(b:, 'go_coverage_build_package', '') isnot# l:pkg
    let b:go_coverage_build_package = l:pkg
    compiler go
  endif
endfun

" Set b:go_coverage_build_tags to the build tags in the current buffer.
fun! go#coverage#go#set_build_tags() abort
  if &buftype isnot# '' || &filetype isnot# 'go'
    return
  endif

  " TODO: be even smarter about this: merge the g: and b: vars, and allow
  " setting a special '%BUFFER%' so you can both set tags from vimrc and merge
  " from file.
  if len(go#coverage#bufsetting('go_coverage_build_tags', '')) > 0
    return
  endif

  let l:tags = go#coverage#go#find_build_tags()
  if l:tags != get(b:, 'go_coverage_build_tags', [])
    let b:go_coverage_build_tags = l:tags
    compiler go
  endif
endfun

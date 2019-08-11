" pkg.vim: Utilities for working with Go packages.

" List all 'importable' packages; this is the stdlib + GOPATH or modules.
fun! gopher#pkg#list_importable() abort
  let [l:out, l:err] = gopher#system#run(['go', 'list', '...'])
  if l:err
    call gopher#error(l:out)
    return []
  endif
  " TODO: cache
  return split(l:out, "\n")
endfun

" List all interfaces for a Go package.
fun! gopher#pkg#list_interfaces(pkg) abort
  let [l:out, l:err] = gopher#system#run(['go', 'doc', a:pkg])
  if l:err
    call gopher#error(l:out)
    return []
  endif

  " TODO: cache.
  return map(filter(split(l:out, "\n"), {_, v -> l:v  =~# '^type \k* interface'}),
        \ {_, v -> split(l:v, " ")[1]})
endfun

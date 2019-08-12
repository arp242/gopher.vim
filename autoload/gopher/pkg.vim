" pkg.vim: Utilities for working with Go packages.

" List all 'importable' packages; this is the stdlib + GOPATH or modules.
fun! gopher#pkg#list_importable() abort
  let l:m = gopher#go#module()
  let l:cache = 'list_import' . (l:m isnot -1 ? l:m : getcwd())

  let [l:out, l:ok] = gopher#system#cache(l:cache)
  if !l:ok
    let [l:out, l:err] = gopher#system#run(['go', 'list', '...'])
    if l:err
      call gopher#error(l:out)
      return []
    endif
    let l:out =  split(l:out, "\n")
    call gopher#system#store_cache(l:out, l:cache)
  endif

  return l:out
endfun

" List all interfaces for a Go package.
fun! gopher#pkg#list_interfaces(pkg) abort
  let [l:out, l:ok] = gopher#system#cache('godoc', a:pkg)
  if !l:ok
    let [l:out, l:err] = gopher#system#run(['go', 'doc', a:pkg])
    if l:err
      call gopher#error(l:out)
      return []
    endif

    let l:out = map(filter(split(l:out, "\n"),
          \ {_, v -> l:v  =~# '^type \k* interface'}),
          \ {_, v -> split(l:v, " ")[1]})
    call gopher#system#store_cache(l:out, 'godoc', a:pkg)
  endif

  return l:out
endfun

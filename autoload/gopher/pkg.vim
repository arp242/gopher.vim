" pkg.vim: Utilities for working with Go packages.

" List all 'importable' packages; this is the stdlib, modules in go.mod, and
" this module's packages.
fun! gopher#pkg#list_importable() abort
  let m = gopher#go#module()
  let cache = 'list_import' . (l:m isnot -1 ? l:m[0] : getcwd())

  let [ret, ok] = gopher#system#cache(l:cache)
  if !ok
    let ret = []
    for l in [['std'], ['-f', '{{.Path}}', '-m', 'all'], ['./...']]
      let [out, err] = gopher#system#run(['go', 'list']->extend(l))
      if err
        call gopher#error(out)
        return []
      endif
      call extend(ret, out->split("\n"))
    endfor
    call gopher#system#store_cache(ret, cache)
  endif
  return ret
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

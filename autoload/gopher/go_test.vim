scriptencoding utf-8
call gopher#init#config()

fun! Test_add_build_tags() abort
  " input, g:gopher_build_tags, want
  let l:tests = [
        \ ['no flags', ['go', 'test'],               [],    ['go', 'test']],
        \ ['add flag', ['go', 'test'],               ['x'], ['go', 'test', '-tags', '"x"']],
        \ ['merge',    ['go', 'test', '-tags', 'y'], ['x'], ['go', 'test', '-tags', '"y x"']],
        \ ['add before pkg', ['go', 'test', 'p'],    ['x'], ['go', 'test', '-tags', '"x"', 'p']],
        \ ['merge before pkg', ['go', 'test', '-tags', 'y', 'p'],    ['x'], ['go', 'test', '-tags', '"y x"', 'p']],
        \ ]

  for l:tt in l:tests
    let [l:name, l:in, g:gopher_build_tags, l:want] = l:tt
    let l:out = gopher#go#add_build_tags(l:in)

    if l:out != l:want
      call Errorf("%s failed\nwant: %s\nout:  %s", l:name, l:want, l:out)
    endif
  endfor
endfun

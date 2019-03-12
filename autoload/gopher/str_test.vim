scriptencoding utf-8
call gopher#init#config()

fun! Test_has_prefix() abort
  let l:tests = [
        \ ['Hello', 'H', 1],
        \ ['Hello', 'Hello', 1],
        \ ['€x', '€', 1],
        \ ['€£', '€', 1],
        \ ['Hello', 'h', 0],
        \ ]

  for l:tt in l:tests
    let [l:str, l:prefix, l:want] = l:tt

    let l:out = gopher#str#has_prefix(l:str, l:prefix)
    if l:out isnot l:want
      call Errorf("has_prefix(%s, %s)\nwant: %d\nout:  %d", l:str, l:prefix, l:want, l:out)
    endif
  endfor
endfun

fun! Test_has_suffix() abort
  let l:tests = [
        \ ['Hello', 'o', 1],
        \ ['Hello', 'Hello', 1],
        \ ['x€', '€', 1],
        \ ['€£', '£', 1],
        \ ['Hello', 'O', 0],
        \ ]

  for l:tt in l:tests
    let [l:str, l:suffix, l:want] = l:tt

    let l:out = gopher#str#has_suffix(l:str, l:suffix)
    if l:out isnot l:want
      call Errorf("has_suffix(%s, %s)\nwant: %d\nout:  %d", l:str, l:suffix, l:want, l:out)
    endif
  endfor
endfun

fun! Test_trim() abort
  let l:tests = [
        \ ['xx', '', 'xx'],
        \ ['xyz', 'x', 'yz'],
        \ ['xyz', 'xy', 'z'],
        \ ['xyz', 'xz', 'y'],
        \ ]

  for l:tt in l:tests
    let [l:in, l:cutset, l:want] = l:tt
    call assert_equal(l:want, gopher#str#trim(l:in, l:cutset), l:in)
  endfor
endfun


fun! Test_trim_space() abort
  let l:tests = {
        \ 'xx':                'xx',
        \ '  xx':              'xx',
        \ 'xx  ':              'xx',
        \ "xx\n":              'xx',
        \ "\txx\t\n":          'xx',
        \ "x  x  \t   \n   ":  'x  x',
        \ "  €ø  \n   ":  '€ø',
        \ }

  for l:k in keys(l:tests)
    call assert_equal(l:tests[l:k], gopher#str#trim_space(l:k), l:k)
  endfor
endfun

fun! Benchmark_trim_space() abort
  let l:s = '  hello  '
  for i in range(0, g:bench_n)
    call gopher#internal#trim_space(l:s)
  endfor
endfun

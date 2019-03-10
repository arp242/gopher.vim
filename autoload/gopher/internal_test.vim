scriptencoding utf-8
call gopher#init#config()

fun! Test_error() abort
  mess clear

  call gopher#internal#error('string')
  call gopher#internal#error(['list1', 'list2'])

  let l:m = split(execute(':messages'), "\n")
  call assert_equal(['gopher.vim: string', 'gopher.vim: list1', 'gopher.vim: list2'], l:m[1:])
endfun

fun! Test_info() abort
  mess clear

  call gopher#internal#info('string')
  call gopher#internal#info(['list1', 'list2'])

  let l:m = split(execute(':messages'), "\n")
  call assert_equal(['gopher.vim: string', 'gopher.vim: list1', 'gopher.vim: list2'], l:m[1:])
endfun

fun! Test_cursor_offset() abort
  new
  call append(0, ['€', 'aaa', 'bbb'])
  call cursor(3, 0)

  let l:out = gopher#internal#cursor_offset()
  call assert_equal(8, l:out)

  let l:out = gopher#internal#cursor_offset(1)
  call assert_equal(':#8', l:out)

  silent w off
  let l:out = gopher#internal#cursor_offset(1)
  call assert_equal(g:test_tmpdir . '/off:#8', l:out)
endfun

fun! Test_lines() abort
  new
  let l:want = ['aaa', 'bbb']
  call append(0, l:want)

  let l:out = gopher#internal#lines()
  call assert_equal(l:want+[''], l:out)

  set fileformat=dos
  silent w lines
  let l:out = gopher#internal#lines()
  call assert_equal(l:want+[''], l:out)
endfun

fun! Test_trim() abort
  let l:tests = {
        \ 'xx':                'xx',
        \ '  xx':              'xx',
        \ 'xx  ':              'xx',
        \ "xx\n":              'xx',
        \ "\txx\t\n":          'xx',
        \ "x  x  \t   \n   ":  'x  x',
        \ }

  for l:k in keys(l:tests)
    call assert_equal(l:tests[l:k], gopher#internal#trim(l:k), l:k)
  endfor
endfun

fun! Benchmark_trim() abort
  let l:s = '  hello  '
  for i in range(0, g:bench_n)
    call gopher#internal#trim(l:s)
  endfor
endfun

fun! Test_diag() abort
  " Just make sure it doesn't error out.
  silent call gopher#internal#diag(0)
endfun

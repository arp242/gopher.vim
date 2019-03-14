fun! Test_lines() abort
  new
  let l:want = ['aaa', 'bbb']
  call append(0, l:want)

  let l:out = gopher#buf#lines()
  call assert_equal(l:want+[''], l:out)

  set fileformat=dos
  silent w lines
  let l:out = gopher#buf#lines()
  call assert_equal(l:want+[''], l:out)
endfun

fun! Test_cursor() abort
  new
  call append(0, ['€', 'aaa', 'bbb'])
  call cursor(3, 0)

  let l:out = gopher#buf#cursor()
  call assert_equal(8, l:out)

  let l:out = gopher#buf#cursor(1)
  call assert_equal(':#8', l:out)

  silent w off
  let l:out = gopher#buf#cursor(1)
  call assert_equal(g:test_tmpdir . '/off:#8', l:out)
endfun

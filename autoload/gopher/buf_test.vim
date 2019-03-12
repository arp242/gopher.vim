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

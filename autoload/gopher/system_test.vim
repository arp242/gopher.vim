fun! Test_tool() abort
  let [l:out, l:err] = gopher#system#tool(['gogetdoc'])
  if !l:err
    call add(v:errors, printf('l:err is not set: %s', l:out))
    return
  endif

  call assert_equal('missing required -pos flag', l:out)
endfun

fun! Test_run() abort
  let [l:out, l:err] = gopher#system#run(['echo', 'one', 'two"'])
  if l:err
    call add(v:errors, printf('l:err is set: %s', l:out))
    return
  endif

  call assert_equal('one two"', l:out)
endfun

fun! Test_restore_env() abort
  let $GOPHER_ENV1 = 'w00t'
  let $GOPHER_ENV2 = 'w00t'

  call gopher#system#restore_env('GOPHER_ENV1', 'original')
  call gopher#system#restore_env('GOPHER_ENV2', '')

  call assert_equal('original', $GOPHER_ENV1)
  " TODO: check that it's unset.
  call assert_equal('', $GOPHER_ENV2)

  call gopher#system#restore_env('GOPHER_ENV1', "quote '\"")
  call assert_equal("quote '\"", $GOPHER_ENV1)
endfun

fun! Test_tmpmod() abort
  exe 'cd ' g:test_tmpdir
  try
    e x
    call setline(1, 'mod')

    let [l:should_tmp, l:tmp1] = gopher#system#tmpmod()
    call assert_equal(l:tmp1, 1, l:should_tmp)

    silent w

    let [l:should_me, l:tmp2] = gopher#system#tmpmod()
    call assert_equal(l:tmp2, 0, l:should_me)
  finally
    call delete('x')
    call delete(l:should_tmp)
    call delete(l:should_me)
  endtry
endfun

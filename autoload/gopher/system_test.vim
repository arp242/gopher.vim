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


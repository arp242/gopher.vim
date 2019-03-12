scriptencoding utf-8
call gopher#init#config()

fun! Test_tool() abort
  let [l:out, l:err] = gopher#system#tool(['guru'])
  if !l:err
    call add(v:errors, printf('l:err is not set: %s', l:out))
    return
  endif

  call assert_equal("Run 'guru -help' for more information.", l:out)
endfun

fun! Test_run() abort
  let [l:out, l:err] = gopher#system#run(['echo', 'one', 'two"'])
  if l:err
    call add(v:errors, printf('l:err is set: %s', l:out))
    return
  endif

  call assert_equal('one two"', l:out)
endfun

fun! Test_job() abort
  let l:done_called = 0
  fun! s:done(exit, out) abort closure
    let l:done_called = 1
    call assert_equal(0, a:exit)
    call assert_equal('one two"', a:out)
  endfun

  let l:job = gopher#system#job(function('s:done'), ['echo', 'one', 'two"'])

  let l:s =  gopher#system#job_wait(l:job)
  if l:s is# 'fail'
    return Error('job status is fail')
  endif

  sleep 50m  " Give time to call s:done
  call assert_equal(1, l:done_called)
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

fun! Test_setup() abort
  " Just call it to make sure it doesn't error out.
  silent call gopher#system#setup()
endfun

fun! Test_history() abort
  " Debug off.
  let l:h = gopher#system#history()
  call assert_equal(l:h, [])

  call gopher#system#_hist_(['ls', '/'], reltime(), 0, "/bin\n/etc\n/root", 0)
  let l:h = gopher#system#history()
  call assert_equal(l:h, [])

  let g:gopher_debug = ['commands']
  call gopher#system#_hist_(['ls', '/'], reltime(), 0, "/bin\n/etc\n/root", 0)
  let l:h = gopher#system#history()
  call assert_equal(1, len(l:h))
endfun

scriptencoding utf-8

fun! Test_error() abort
  call gopher#internal#error('string')
  call gopher#internal#error(['list1', 'list2'])

  let l:m = split(execute(':message'), "\n")
  mess clear

  call assert_equal(['gopher.vim: string', 'gopher.vim: list1', 'gopher.vim: list2'], l:m[1:])
endfun

fun! Test_info() abort
  call gopher#internal#info('string')
  call gopher#internal#info(['list1', 'list2'])

  let l:m = split(execute(':message'), "\n")
  mess clear

  call assert_equal(['gopher.vim: string', 'gopher.vim: list1', 'gopher.vim: list2'], l:m[1:])
endfun

fun! Test_restore_env() abort
  let $GOPHER_ENV1 = 'w00t'
  let $GOPHER_ENV2 = 'w00t'

  call gopher#internal#restore_env('GOPHER_ENV1', 'original')
  call gopher#internal#restore_env('GOPHER_ENV2', '')

  call assert_equal('original', $GOPHER_ENV1)
  " TODO: check that it's unset.
  call assert_equal('', $GOPHER_ENV2)

  call gopher#internal#restore_env('GOPHER_ENV1', "quote '\"")
  call assert_equal("quote '\"", $GOPHER_ENV1)
endfun

fun! Test_tool() abort
  let [l:out, l:err] = gopher#internal#tool(['gogetdoc'])
  if !l:err
    call add(v:errors, printf('l:err is not set: %s', l:out))
    return
  endif

  call assert_equal('missing required -pos flag', l:out)
endfun

fun! Test_system() abort
  let [l:out, l:err] = gopher#internal#system(['echo', 'one', 'two"'])
  if l:err
    call add(v:errors, printf('l:err is set: %s', l:out))
    return
  endif

  call assert_equal('one two"', l:out)
endfun

fun! Test_cursor_offset() abort
  new
  call append(0, ['€', 'aaa', 'bbb'])
  call cursor(3, 0)

  let l:out = gopher#internal#cursor_offset()
  call assert_equal(8, l:out)
endfun

fun! Test_lines() abort
  new
  let l:want = ['aaa', 'bbb']

  call append(0, l:want)
  let l:out = gopher#internal#lines()

  call assert_equal(l:want+[''], l:out)
endfun

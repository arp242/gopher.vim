scriptencoding utf-8
call gopher#init#config()

fun! Test_error() abort
  mess clear

  call gopher#internal#error('string')
  call gopher#internal#error('%d %s', 666, 'fmt')
  call gopher#internal#error(['list1', 'list2'])

  let l:m = split(execute(':messages'), "\n")
  call assert_equal(['gopher.vim: string', 'gopher.vim: 666 fmt', 'gopher.vim: list1', 'gopher.vim: list2'], l:m[1:])
  mess clear
endfun

fun! Test_info() abort
  mess clear

  call gopher#internal#info('string')
  call gopher#internal#error('%d %s', 666, 'fmt')
  call gopher#internal#info(['list1', 'list2'])

  let l:m = split(execute(':messages'), "\n")
  call assert_equal(['gopher.vim: string', 'gopher.vim: 666 fmt', 'gopher.vim: list1', 'gopher.vim: list2'], l:m[1:])
  mess clear
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

fun! Test_diag() abort
  " Just make sure it doesn't error out.
  silent call gopher#internal#diag(0)
endfun

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
    let l:out = gopher#internal#add_build_tags(l:in)

    if l:out != l:want
      call Errorf("%s failed\nwant: %s\nout:  %s", l:name, l:want, l:out)
    endif
  endfor
endfun

scriptencoding utf-8
call gopher#init#config()

fun! Test_error() abort
  mess clear

  call gopher#error('string')
  call gopher#error('%d %s', 666, 'fmt')
  call gopher#error(['list1', 'list2'])

  let l:m = split(execute(':messages'), "\n")
  call assert_equal(['gopher.vim: string', 'gopher.vim: 666 fmt', 'gopher.vim: list1', 'gopher.vim: list2'], l:m[1:])
  mess clear
endfun

fun! Test_info() abort
  mess clear

  call gopher#info('string')
  call gopher#error('%d %s', 666, 'fmt')
  call gopher#info(['list1', 'list2'])

  let l:m = split(execute(':messages'), "\n")
  call assert_equal(['gopher.vim: string', 'gopher.vim: 666 fmt', 'gopher.vim: list1', 'gopher.vim: list2'], l:m[1:])
  mess clear
endfun

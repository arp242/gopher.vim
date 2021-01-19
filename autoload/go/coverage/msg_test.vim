scriptencoding utf-8
call gopher#init#config()

fun! Test_error() abort
  mess clear

  call gopher#error('string')
  call gopher#error('%d %s', 666, 'fmt')
  call gopher#error(['list1', 'list2'])

  let l:m = split(execute(':messages'), "\n")
  let l:out = l:m[0][:20] is# 'Messages maintainer: ' ? l:m[1:] : l:m[0:]
  let l:want = ['gopher.vim: string', 'gopher.vim: 666 fmt', 'gopher.vim: list1', 'gopher.vim: list2']

  if l:out != l:want
    call Errorf("\nwant: %s\nout:  %s", l:want, l:out)
  endif

  mess clear
endfun

fun! Test_info() abort
  return
  mess clear

  call gopher#info('string')
  call gopher#error('%d %s', 666, 'fmt')
  call gopher#info(['list1', 'list2'])

  let l:m = split(execute(':messages'), "\n")
  let l:out = l:m[0][:20] is# 'Messages maintainer: ' ? l:m[1:] : l:m[0:]
  let l:want = ['gopher.vim: string', 'gopher.vim: 666 fmt', 'gopher.vim: list1', 'gopher.vim: list2']

  if l:out != l:want
    call Errorf("\nwant: %s\nout:  %s", l:want, l:out)
  endif

  mess clear
endfun

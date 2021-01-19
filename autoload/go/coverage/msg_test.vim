scriptencoding utf-8
call go#coverage#init#config()

fun! Test_error() abort
  mess clear

  call go#coverage#msg#error('string')
  call go#coverage#msg#error('%d %s', 666, 'fmt')
  call go#coverage#msg#error(['list1', 'list2'])

  let l:m = split(execute(':messages'), "\n")
  let l:out = l:m[0][:20] is# 'Messages maintainer: ' ? l:m[1:] : l:m[0:]
  let l:want = ['coverage.vim: string', 'coverage.vim: 666 fmt', 'coverage.vim: list1', 'coverage.vim: list2']

  if l:out != l:want
    call Errorf("\nwant: %s\nout:  %s", l:want, l:out)
  endif

  mess clear
endfun

fun! Test_info() abort
  return
  mess clear

  call go#coverage#msg#info('string')
  call go#coverage#msg#error('%d %s', 666, 'fmt')
  call go#coverage#msg#info(['list1', 'list2'])

  let l:m = split(execute(':messages'), "\n")
  let l:out = l:m[0][:20] is# 'Messages maintainer: ' ? l:m[1:] : l:m[0:]
  let l:want = ['coverage.vim: string', 'coverage.vim: 666 fmt', 'coverage.vim: list1', 'coverage.vim: list2']

  if l:out != l:want
    call Errorf("\nwant: %s\nout:  %s", l:want, l:out)
  endif

  mess clear
endfun

scriptencoding utf-8
call gopher#init#config()

fun! Test_rename() abort
  " Skip this test as it needs to setup GOPATH.
  " TODO: maybe add Skip to testing.vim?
  return

  let l:input = ['package a', '', 'var a = 1']
  let l:want = ['package a', '', 'var b = 1', '']

  new
  call append(0, l:input)
  call setpos('.', [bufnr(''), 3, 5, 0])
  silent w rename.go

  call gopher#rename#do('b')
  let l:got = gopher#buf#lines()
  if l:want != l:got
    call Errorf("want: %s\ngot:  %s", l:want, l:got)
  endif
endfun

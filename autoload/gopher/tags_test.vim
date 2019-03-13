scriptencoding utf-8
call gopher#init#config()

fun! Test_tags() abort
  let l:input = ['package a',
      \ '',
      \ 'type x struct {',
      \ "\tFoo int",
      \ "\tbar int",
      \ '}']

  silent exe 'e tags.go'
  call append(0, l:input)
  call setpos('.', [bufnr(''), 4, 1, 0])
  silent w

  " Add tags based on offset.
  let l:want = ['package a',
      \ '',
      \ 'type x struct {',
      \ "\tFoo int `xx:\"foo\"`",
      \ "\tbar int `xx:\"bar\"`",
      \ '}', '']
  call gopher#tags#modify(0, 0, -1, 'xx')
  let l:got = gopher#buf#lines()
  if l:want != l:got
    call Errorf("want: %s\ngot:  %s", l:want, l:got)
  endif

  " Remove tag from one line.
  let l:want = ['package a',
      \ '',
      \ 'type x struct {',
      \ "\tFoo int ",
      \ "\tbar int `xx:\"bar\"`",
      \ '}', '']
  call gopher#tags#modify(4, 4, 1, '-rm', 'xx')
  let l:got = gopher#buf#lines()
  if l:want != l:got
    call Errorf("want: %s\ngot:  %s", l:want, l:got)
  endif

  " Remove all based on offset.
  let l:want = l:input + ['']
  call gopher#tags#modify(0, 0, -1, '-rm')
  silent %s/ *$//g  " Leaves trailing whitespace.
  let l:got = gopher#buf#lines()
  if l:want != l:got
    call Errorf("want: %s\ngot:  %s", l:want, l:got)
  endif
endfun

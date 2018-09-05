fun! Test_auto_to() abort
  let l:tests = {
        \ 'hello': 'Hello',
        \ 'Hello': 'hello',
        \ 'helloWorld': 'HelloWorld',
        \ 'HelloWorld': 'helloWorld',
        \ 'HELLO': 'Hello',
        \ 'HELLO_WORLD': 'HelloWorld',
        \ 'hello_world': 'helloWorld',
        \ }
  for l:k in keys(l:tests)
    call assert_equal(l:tests[l:k], gopher#rename#_auto_to(l:k), l:k)
  endfor
endfun

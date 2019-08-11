scriptencoding utf-8
call gopher#init#config()

fun! Test_word() abort
  let l:tests = [
        \ ['a b', 3, 'b'],
        \ ['a b cc', 6, 'cc'],
        \ ['a b cc', 5, 'cc'],
      \]

  for l:tt in l:tests
    let [l:cmdline, l:cursor, l:want] = l:tt
    let l:out = gopher#compl#word(l:cmdline, l:cursor)
    if l:out isnot l:want
      call Errorf("word(%s, %s)\nwant: %s\nout:  %s", l:cmdline, l:cursor, l:want, l:out)
    endif
  endfor
endfun

fun! Test_prev_word() abort
  let l:tests = [
        \ ['a b', 3, 'a'],
        \ ['a b cc', 5, 'b'],
        \ ['GoImport -rm ', 13, '-rm'],
      \]

  for l:tt in l:tests
    let [l:cmdline, l:cursor, l:want] = l:tt
    let l:out = gopher#compl#prev_word(l:cmdline, l:cursor)
    if l:out isnot l:want
      call Errorf("word(%s, %s)\nwant: %s\nout:  %s", l:cmdline, l:cursor, l:want, l:out)
    endif
  endfor
endfun

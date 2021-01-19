scriptencoding utf-8
call go#coverage#init#config()

fun! Test_has_suffix() abort
  let l:tests = [
        \ ['Hello', 'o', 1],
        \ ['Hello', 'Hello', 1],
        \ ['x€', '€', 1],
        \ ['€£', '£', 1],
        \ ['Hello', 'O', 0],
        \ ]

  for l:tt in l:tests
    let [l:str, l:suffix, l:want] = l:tt

    let l:out = go#coverage#str#has_suffix(l:str, l:suffix)
    if l:out isnot l:want
      call Errorf("has_suffix(%s, %s)\nwant: %d\nout:  %d", l:str, l:suffix, l:want, l:out)
    endif
  endfor
endfun

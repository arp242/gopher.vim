scriptencoding utf-8
call gopher#init#config()

fun! Test_merge() abort
  let l:tests = [
          \ ['', {}, {}, '{}'],
          \ ['', {'a': 'b', 'c': 'd'}, {'a': 'x'}, "{'a': 'x', 'c': 'd'}"],
          \ [ '',
              \ {'a': 'b', 'c': {'d': 'e'}},
              \ {'c': {'new': 'x'}},
              \ "{'a': 'b', 'c': {'d': 'e', 'new': 'x'}}"],
          \ [ '',
              \ {'a': 'b', 'c': {'d': {'e': 'f'}}},
              \ {'c': {'d': {'e': 'x'}}},
              \ "{'a': 'b', 'c': {'d': {'e': 'x'}}}"],
          \ [ '',
              \ {},
              \ {'a': {'new': 'x'}},
              \ "{'a': {'new': 'x'}}"],
          \ [ ' dict override string',
              \ {'a': 'b'},
              \ {'a': {'new': 'x'}},
              \ "{'a': {'new': 'x'}}"],
          \ [ ' override is str while original is dict: just clobber it.',
              \ {'a': {'b': 'c'}},
              \ {'a': 'x'},
              \ "{'a': 'x'}"],
          \ ]

  for l:tt in l:tests
    let [_, l:defaults, l:override, l:want] = l:tt
    let l:out = printf('%s', gopher#dict#merge(l:defaults, l:override))
    if l:out isnot l:want
      call Errorf("merge(%s, %s)\nwant: %s\nout:  %s", l:defaults, l:override, l:want, l:out)
    endif
  endfor
endfun

scriptencoding utf-8
call gopher#init#config()

fun! Test_highlight() abort
  new
  call append(0, ['nothing', 'nothing', 'good', 'nothing', 'uncov', 'uncov'])
  call gopher#coverage#_highlight_({'cnt': 1, 'startline': 3, 'startcol': 0, 'endline': 3, 'endcol': 4})
  call gopher#coverage#_highlight_({'cnt': 0, 'startline': 5, 'startcol': 0, 'endline': 6, 'endcol': 5})

  let l:want = [
        \ {'group': 'goCoverageCovered', 'id': 4, 'priority': 10, 'pos1': [3]},
        \ {'group': 'goCoverageUncover', 'id': 5, 'priority': 10, 'pos1': [5]},
        \ {'group': 'goCoverageUncover', 'id': 6, 'priority': 10, 'pos1': [6]},
        \ {'group': 'goCoverageUncover', 'id': 7, 'priority': 10, 'pos1': [6, 4, 1],
        \ }]

  call assert_equal(l:want, getmatches())
endfun

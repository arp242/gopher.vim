scriptencoding utf-8
call gopher#init#config()

fun! Test_highlight() abort
  let l:in = [
        \ 'package a',
        \ '',
        \ 'import "fmt"',
        \ '',
        \ 'func a() { fmt.Println("a") }',
        \ 'func b() {}',
        \ 'func c() {',
        \ '	fmt.Println("c")',
        \ '}']

  let l:test = ['package a', 'import "testing"',
              \ 'func TestX(t *testing.T) { a(); c() }']

  new
  call setline(1, l:test)
  silent wq a_test.go

  new
  call setline(1, 'module a')
  silent wq go.mod

  new
  call setline(1, l:in)
  silent w a.go

  call gopher#coverage#do()

  let l:want = [
        \ {'group': 'goCoverageCovered', 'priority': 10, 'pos1': [5, 10, 20]},
        \ {'group': 'goCoverageUncover', 'priority': 10, 'pos1': [6, 11, 1]},
        \ {'group': 'goCoverageCovered', 'priority': 10, 'pos1': [7, 10, 0]},
        \ {'group': 'goCoverageCovered', 'priority': 10, 'pos1': [8]},
        \ {'group': 'goCoverageCovered', 'priority': 10, 'pos1': [9]},
        \ {'group': 'goCoverageCovered', 'priority': 10, 'pos1': [9, 1, 1]}]
  " Remove id as it's not stable.
  let l:got = map(getmatches(), {i, v -> remove(l:v, 'id') is '' ? {} : l:v })

  if l:got != l:want
    call Errorf("want: %s\ngot:  %s\n", l:want, l:got)
  endif

  call gopher#coverage#do('clear')
  call assert_equal([], getmatches())
endfun

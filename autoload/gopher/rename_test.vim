fun! Test_error() abort
  " /home/martin/go/src/a/a.go:18:2: undeclared name: x
  " /home/martin/go/src/a/a.go:19:2: undeclared name: x
  " gorename: couldn't load packages due to errors: a
  "
  " gorename: -offset "/home/martin/go/src/a/dir1/asd.go:#38": no identifier at this position
  "
  " /home/martin/go/src/a/dir1/asd.go:5:6: renaming this func "QWEzxcasdzxc" to "x"
  " /home/martin/go/src/a/dir1/dir1.go:5:6: <09>conflicts with func in same block
  "
  " /home/martin/go/src/a/dir1/asd.go:7:2: renaming this var "v" to "asd"
  " /home/martin/go/src/a/dir1/asd.go:6:2: <09>conflicts with var in same block

  let l:tests = [
        \{
        \ 'in': "gorename: -offset \"/home/martin/go/src/a/a.go:#125\": cannot parse file: /home/martin/go/src/a/a.go:18:2: expected 'IDENT', found 'EOF'",
        \ 'want': [{
            \ 'lnum': 18, 'bufnr': 2, 'col': 2,
            \ 'pattern': '',
            \ 'valid': 1, 'vcol': 0, 'nr': 0, 'type': 'E', 'module': '',
            \ 'text': ' expected ''IDENT'', found ''EOF'''
            \ }],
        \},
        \{
        \ 'in': "gorename: -offset \"/home/martin/go/src/a/a.go:#269\": cannot parse file: /home/martin/go/src/a/a.go:17:1: expected declaration, found asde",
        \ 'want': [{
            \ 'lnum': 17, 'bufnr': 2, 'col': 1,
            \ 'pattern': '',
            \ 'valid': 1, 'vcol': 0, 'nr': 0, 'type': 'E', 'module': '',
            \ 'text': ' expected declaration, found asde'
            \ }],
        \}
  \]

  for l:tt in l:tests
    call gopher#rename#_errors(l:tt.in, 0)

    call assert_equal(l:tt.want, getqflist())
    call setqflist([])
  endfor
endfun

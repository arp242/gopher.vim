scriptencoding utf-8
call gopher#init#config()

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

endfun

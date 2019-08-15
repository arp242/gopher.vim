scriptencoding utf-8
call gopher#init#config()

fun! Test_version_check() abort
  let l:tests = [ 'go version go1.11.5 linux/amd64', 'go version go1.12 linux/amd64',
                \ 'go version devel +e37a1b1ca6 Tue Aug 6 23:05:55 2019 +0000 darwin/amd64']
  for l:tt in l:tests
    if !gopher#init#version_check(l:tt)
      call Errorf('version check failed for %s', l:tt)
    endif
  endfor
endfun

if exists('g:current_compiler')
  finish
endif
let g:current_compiler = 'golint'
let s:save_cpo = &cpoptions
set cpoptions-=C

" CompilerSet makeprg=golangci-lint
let &l:makeprg = 'golangci-lint run --out-format tab'
if len(get(g:, 'gopher_build_tags', [])) > 0
  let &l:makeprg .= printf(' --build-tags "%s"', join(gopher#bufsetting('gopher_build_tags', []) ' '))
endif

" golangci-lint:
"   benchmark_test.go:34:2   deadcode  `valFormT2` is unused
"   formam.go:201:21         gosimple  S1002: should omit comparison to bool constant, can be simplified to `!inBracket`
"
" staticcheck: needs extra ':':
"   hit.go:119:6: unnecessary assignment to the blank identifier (S1005)
"
" go vet needs ignoring lines that start with '#':
"   # zgo.at/goatcounter
"   ./hit.go:38:2: struct field tag `db: "id" json:"-"` not compatible with reflect.StructTag.Get: bad syntax for struct tag value
let &l:errorformat = '%-G# %.%#,%f:%l:%c:\\? %m'

let &cpoptions = s:save_cpo
unlet s:save_cpo

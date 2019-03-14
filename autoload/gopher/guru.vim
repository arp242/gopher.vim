" guru.vim: implement the :GoGuru command.

let s:commands = ['callees', 'callers', 'callstack', 'definition', 'describe',
                \ 'freevars', 'implements', 'peers', 'pointsto', 'referrers',
                \ 'what', 'whicherrs']

fun! gopher#guru#complete(lead, cmdline, cursor) abort
  " TODO: complete -scope with packages.
  return filter(s:commands + ['-scope', '-tags', '-reflect'],
        \ {i, v -> strpart(l:v, 0, len(a:lead)) is# a:lead})
endfun

" TODO: commands need range: freevars
fun! gopher#guru#do(...) abort
  " Prepend -scope flag unless given in the command.
  let l:flags = a:000
  if index(l:flags, '-scope') is -1
    let l:flags = ['-scope', get(g:, 'gopher_guru_scope', gopher#go#package())] + l:flags
  endif

  " TODO: pass stdin to tool_job: gopher#system#archive()
  call gopher#system#tool_job(function('s:done'), gopher#go#add_build_tags(
        \ ['guru']
        \ + (&modified ? ['-modified'] : [])
        \ + l:flags
        \ + [gopher#buf#cursor(1)]))
endfun

fun! s:done(exit, out) abort
  if a:exit > 0
    " TODO: add hint about scope if appropriate.
    return gopher#error(a:out)
  endif

  call gopher#qf#populate(a:out, '', 'guru')
endfun

" JSON outputs

" callees:
" {
"         "pos": "/data/code/formam/formam.go:133:10",
"         "desc": "static function call",
"         "callees": [
"         	{
"         		"name": "reflect.ValueOf",
"         		"pos": "/usr/lib/go/src/reflect/value.go:2252:6"
"         	}
"         ]
" }
"
" callers:
" [
"         {
"         	"pos": "/data/code/formam/formam_test.go:709:22",
"         	"desc": "static function call",
"         	"caller": "github.com/monoculum/formam_test.TestDecodeInSlice"
"         },
"         {
"         	"pos": "/data/code/formam/benchmark_test.go:397:26",
"         	"desc": "static function call",
"         	"caller": "github.com/monoculum/formam_test.BenchmarkComplex"
"         }
" ]
"
" callstack
" {
"         "pos": "/data/code/formam/formam.go:132:6",
"         "target": "github.com/monoculum/formam.Decode",
"         "callers": [
"         	{
"         		"pos": "/data/code/formam/formam_test.go:709:22",
"         		"desc": "static function call",
"         		"caller": "github.com/monoculum/formam_test.TestDecodeInSlice"
"         	},
"         	{
"         		"pos": "/usr/lib/go/src/testing/testing.go:865:4",
"         		"desc": "dynamic function call",
"         		"caller": "testing.tRunner"
"         	},
"         	{
"         		"pos": "/usr/lib/go/src/testing/testing.go:1155:11",
"         		"desc": "static function call",
"         		"caller": "testing.runTests"
"         	},
"         	{
"         		"pos": "/usr/lib/go/src/testing/testing.go:1072:29",
"         		"desc": "static function call",
"         		"caller": "(*testing.M).Run"
"         	}
"         ]
" }
"
" describe:
" {
"         "desc": "identifier",
"         "pos": "/home/martin/code/formam/formam.go:134:28",
"         "detail": "value",
"         "value": {
"         	"type": "reflect.Kind",
"         	"value": "22",
"         	"objpos": "/usr/lib/go/src/reflect/type.go:252:2",
"         	"typespos": [
"         		{
"         			"objpos": "/usr/lib/go/src/reflect/type.go:227:6",
"         			"desc": "reflect.Kind"
"         		}
"         	]
"         }
" }
"
" definition
" {
"         "objpos": "/usr/lib/go/src/reflect/value.go:2252:6",
"         "desc": "func reflect.ValueOf"
" }
"
" freevars
" TODO
"
" implements
" {
"         "type": {
"         	"name": "a.i",
"         	"pos": "/home/martin/go/src/a/a.go:8:6",
"         	"kind": "interface"
"         },
"         "to": [
"         	{
"         		"name": "a.a",
"         		"pos": "/home/martin/go/src/a/a.go:12:6",
"         		"kind": "struct"
"         	},
"         	{
"         		"name": "a.b",
"         		"pos": "/home/martin/go/src/a/a.go:16:6",
"         		"kind": "struct"
"         	}
"         ]
" }
"
" peers
" {
"         "pos": "/home/martin/go/src/a/a.go:36:5",
"         "type": "chan int",
"         "allocs": [
"         	"/home/martin/go/src/a/a.go:35:12"
"         ],
"         "sends": [
"         	"/home/martin/go/src/a/a.go:36:5"
"         ],
"         "receives": [
"         	"/home/martin/go/src/a/a.go:38:14"
"         ]
" }
"
" pointsto
" [
"         {
"         	"type": "a",
"         	"namepos": "/home/martin/go/src/a/a.go:12:6"
"         },
"         {
"         	"type": "b",
"         	"namepos": "/home/martin/go/src/a/a.go:16:6"
"         }
" ]
"
" referrers
" {
"         "objpos": "/home/martin/go/src/a/a.go:36:7",
"         "desc": "const a.ZZZ untyped string"
" }
" {
"         "package": "a",
"         "refs": [
"         	{
"         		"pos": "/home/martin/go/src/a/a.go:33:14",
"         		"text": "\tfmt.Println(ZZZ)"
"         	},
"         	{
"         		"pos": "/home/martin/go/src/a/b.go:6:14",
"         		"text": "\tfmt.Println(ZZZ)"
"         	}
"         ]
" }
"
" what
" {
"         "enclosing": [
"         	{
"         		"desc": "identifier",
"         		"start": 157,
"         		"end": 158
"         	},
"         	{
"         		"desc": "field/method/parameter",
"         		"start": 155,
"         		"end": 158
"         	},
"         	{
"         		"desc": "field/method/parameter list",
"         		"start": 154,
"         		"end": 159
"         	},
"         	{
"         		"desc": "function declaration",
"         		"start": 149,
"         		"end": 187
"         	},
"         	{
"         		"desc": "source file",
"         		"start": 0,
"         		"end": 372
"         	}
"         ],
"         "modes": [
"         	"callers",
"         	"callstack",
"         	"definition",
"         	"describe",
"         	"implements",
"         	"pointsto",
"         	"referrers",
"         ],
"         "srcdir": "/home/martin/go/src",
"         "importpath": "a",
"         "object": "b",
"         "sameids": [
"         	"/home/martin/go/src/a/a.go:16:6",
"         	"/home/martin/go/src/a/a.go:18:9",
"         	"/home/martin/go/src/a/a.go:25:10"
"         ]
" }
"
" whicherr:
" {
"         "errpos": "/data/code/formam/formam.go:154:6",
"         "types": [
"                 {
"                         "type": "*Error",
"                         "position": "/data/code/formam/errors.go:8:6"
"                 },
"                 {
"                         "type": "*time.ParseError",
"                         "position": "/usr/lib/go/src/time/format.go:657:6"
"                 }
"         ]
" }

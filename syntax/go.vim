if exists('b:current_syntax')
  finish
endif

" The ftplugin is loaded after the syntax file, so load it here too.
call gopher#init#config()

fun! s:has_setting(n)
  return index(g:gopher_highlight, a:n) > -1
endfun

syn case match

" Keywords.
syn keyword     goPackage         package
syn keyword     goImport          import    contained
syn keyword     goVar             var       contained
syn keyword     goConst           const     contained
syn keyword     goDeclaration     func type struct interface

" Keywords within functions.
syn keyword     goStatement       defer go goto return break continue fallthrough
syn keyword     goConditional     if else switch select
syn keyword     goLabel           case default
syn keyword     goRepeat          for range

" TODO: Use @42<! instead of @<! ?

" Predefined identifiers; don't use keywords to ensure that method names and
" cals don't get highlighted.
"
" /\v<\.@<!%(int)>\ze(\((.{} .{})?\))@!
"
" (\k\) )@<!          Don't match 'e) ' in '(recv type) int'
" (\k\.)@<!           Don't match Match 'o.' in 'foo.int'
"
" Don't match int():
"   \ze                 Set end of match here
"   (
"     \(                Literal (
"     ([^,]{} [^,]{})?        Match argument; 'a string' in 'func int(a string)'
"     \)                Literal )
"   )@!                 Match zero-width if group does NOT match
syn match        goBoolean        /\v\.@<!%(true|false|nil|iota)>\ze([^\(]|$)/
syn match        goType           /\v(\k\) )@<!<(\k\.)@<!%(chan|map|bool|string|error|int64|int8|int16|int32|int|rune|byte|uint64|uint8|uint16|uint32|uintptr|uint|float32|float64|complex64|complex128)>/

" Highlight builtin functions, to prevent accidental overriding. Do not match
" when it's a method function name or method call.
" Test: builtin.go
"
" TODO: this is a bit slow (second slowest is goSingleDecl at ~0.35); different
" variants I tried:
" 0.064089   5294   160     0.000059    0.000012  goBuiltins         \v(\.|\))@<!<(append|cap|..
" 0.074896   5278   132     0.000367    0.000014  goBuiltins         \v(\.|\) )@<!<(append|..)\ze[^a-zA-Z0-9_]
" 0.165187   5294   160     0.000152    0.000031  goBuiltins         \v<(\.|\))@<!(append|cap|..
" 0.761366   5328   194     0.000943    0.000143  goBuiltins         \v(\.|\) )@<!(append|cap|..
" 1.000724   5328   194     0.000956    0.000188  goBuiltins         \v[^.]@<=(append|cap|..
" TOTAL      COUNT  MATCH   SLOWEST     AVERAGE   NAME               PATTERN
syn match goBuiltins /\v%(\.|\) )@<!<(append|cap|close|complex|copy|delete|imag|len|make|new|panic|print|println|real|recover)\ze[^a-zA-Z0-9_]/

" Comments blocks.
syn keyword     goTodo            contained TODO FIXME XXX BUG
syn region      goComment         start="//" end="$"    contains=goCompilerDir,goGenerate,goDirectiveErr,goBuildTag,goTodo,@Spell

if s:has_setting('fold-comment')
  syn region    goComment         start="/\*" end="\*/" contains=goTodo,@Spell fold
  syn match     goComment         "\v(^\s*//.*\n)+"     contains=goCompilerDir,goGenerate,goDirectiveErr,goBuildTag,goTodo,@Spell fold
else
  syn region    goComment         start="/\*" end="\*/" contains=goTodo,@Spell
endif

" go:generate; see go help generate
syn match       goGenerateKW      display contained /go:generate/
syn match       goGenerateVars    contained /\v\$(GOARCH|GOOS|GOFILE|GOLINE|GOPACKAGE|DOLLAR)/
syn region      goGenerate        contained matchgroup=goGenerateKW start="^//go:generate" end="$" contains=goGenerateVars,goGenerateKW

" Compiler directives.
" https://golang.org/cmd/compile/#hdr-Compiler_Directives
" pragmaValue in cmd/compile/internal/gc/lex.go
" TODO: //go:linkname localname importpath.name
" TODO: support line directives.
syn match       goCompilerDir     display contained "\v^//go:(nointerface|noescape|norace|nosplit|noinline|systemstack|nowritebarrier|nowritebarrierrec|yeswritebarrierrec|cgo_unsafe_args|uintptrescapes|notinheap)$"

" Adding a space between the // and go: is an error.
syn region      goDirectiveErr    contained matchgroup=Error start="^// go:\w\+" end="$"

" Build tags; standard build tags from cmd/dist/build.go and go doc go/build.
syn match   goBuildKeyword        display contained "+build"
syn keyword goStdBuildTags        contained
      \ 386 amd64 amd64p32 arm arm64 mips mipsle mips64 mips64le ppc64 ppc64le
      \ riscv64 s390x wasm darwin dragonfly hurd js linux android solaris
      \ freebsd nacl netbsd openbsd plan9 windows gc gccgo cgo race
syn match   goVersionBuildTags    contained /\v<go1\.(10|11|1|2|3|4|5|6|7|8|9)>/

" The rs=s+2 option lets the \s*+build portion be part of the inner region
" instead of the matchgroup so it will be highlighted as a goBuildKeyword.
syn region  goBuildTag            contained matchgroup=goBuildTagStart
      \ start="^//\s*+build\s"rs=s+2 end="$"
      \ contains=goBuildKeyword,goStdBuildTags,goVersionBuildTags

" String escapes.
syn match       goEscapeOctal     display contained "\\[0-7]\{3}"
syn match       goEscapeC         display contained +\\[abfnrtv\\'"]+
syn match       goEscapeX         display contained "\\x\x\{2}"
syn match       goEscapeU         display contained "\\u\x\{4}"
syn match       goEscapeBigU      display contained "\\U\x\{8}"
syn match       goEscapeError     display contained +\\[^0-7xuUabfnrtv\\'"]+
syn cluster     goStringGroup     contains=goEscapeOctal,goEscapeC,goEscapeX,goEscapeU,goEscapeBigU,goEscapeError

" Strings
if s:has_setting('string-spell')
  syn region    goString          start=/"/ end=/"/ contains=@goStringGroup,@Spell
  syn region    goRawString       start=/`/ end=/`/ contains=@Spell
else
  syn region    goString          start=/"/ end=/"/ contains=@goStringGroup
  syn region    goRawString       start=/`/ end=/`/
endif

" Struct tag name.
syn match       goStructTagName   /\w\{-1,}:"/he=e-2 contained containedin=goRawString

if s:has_setting('string-fmt')
  " [n] notation is valid for specifying explicit argument indexes
  " 1. literal % not preceded by a %.
  " 2. any number of -, #, 0, space, or +
  " 3. * or [n]* or any number or nothing before a .
  " 4. * or [n]* or any number or nothing after a .
  " 5. [n] or nothing before a verb
  " 6. formatting verb
  syn match       goFormatSpecifier   /\
        \([^%]\(%%\)*\)\
        \@<=%[-#0 +]*\
        \v%(%(%(\[\d+])?\*)|\d+)?\
        \v%(\.%(%(%(\[\d+])?\*)|\d+)?)?\
        \v%(\[\d+])?[vTtbcdoqxXUeEfFgGspw]/ contained containedin=goString,goRawString
endif

" Character.
syn cluster     goCharacterGroup  contains=goEscapeOctal,goEscapeC,goEscapeX,goEscapeU,goEscapeBigU
syn region      goCharacter       start=/'/ end=/'/ contains=@goCharacterGroup

" Regions
syn region      goParen           start='(' end=')' transparent
if s:has_setting('fold-block')
  syn region    goBlock           start="{" end="}" transparent fold
else
  syn region    goBlock           start="{" end="}" transparent
endif

" import
if s:has_setting('fold-import')
  syn region    goImport          start='import (' end=')' transparent fold contains=goImport,goString,goComment
else
  syn region    goImport          start='import (' end=')' transparent contains=goImport,goString,goComment
endif

" var, const
if s:has_setting('fold-varconst')
  syn region    goVar             start='var ('   end='^\s*)$' transparent fold contains=ALLBUT,goParen,goBlock
  syn region    goConst           start='const (' end='^\s*)$' transparent fold contains=ALLBUT,goParen,goBlock
else
  syn region    goVar             start='var ('   end='^\s*)$' transparent contains=ALLBUT,goParen,goBlock
  syn region    goConst           start='const (' end='^\s*)$' transparent contains=ALLBUT,goParen,goBlock
endif

" Single-line var, const, and import.
syn match       goSingleDecl      /\v(^\s*)@<=(import|var|const) [^(]/me=e-2 contains=goImport,goVar,goConst

"   <         # Word boundary
"   -?        # Optional -
"   \d+       # Any amount of digits
"   %(
"      [Ee]   # Optionally match exponent part of scientific notation.
"      [-+]?
"      \d+
"   )?
syn match       goDecimalInt      /\v<-?\d+%([Ee][-+]?\d+)?>/
syn match       goHexadecimalInt  /\v<-?0[xX]\x+>/
syn match       goOctalInt        /\v<-?0\o+>/
syn match       goOctalError      /\v<-?0\o*[89]\d*>/

" Floating points.
syn match       goFloat           /\v<-?\d+\.\d*%([Ee][-+]?\d+)?>/
syn match       goFloat           /\v<-?\.\d+%([Ee][-+]?\d+)?>/

" Complex numbers.
if s:has_setting('complex')
  syn match     goImaginary       /\v<-?\d+i>/
  syn match     goImaginary       /\v<-?\d+[Ee][-+]?\d+i>/
  syn match     goImaginaryFloat  /\v<-?\d+\.\d*%([Ee][-+]?\d+)?i>/
  syn match     goImaginaryFloat  /\v<-?\.\d+%([Ee][-+]?\d+)?i>/
endif

" One or more line comments that are followed immediately by a "package"
" declaration are treated like package documentation, so these must be
" matched as comments to avoid looking like working build constraints.
" The he, me, and re options let the "package" itself be highlighted by
" the usual rules.

" TODO: runs out of memory in mattn/gtk
exe 'syn region  goPackageComment    start=/\v(\/\/.*\n)+\s*package/'
      \ . ' end=/\v\n\s*package/he=e-7,me=e-7,re=e-7'
      \ . ' contains=goTodo,@Spell'
      \ . (s:has_setting('fold-pkg-comment') ? ' fold' : '')
exe 'syn region  goPackageComment    start=/\v^\s*\/\*.*\n(.*\n)*\s*\*\/\npackage/'
      \ . ' end=/\v\*\/\n\s*package/he=e-7,me=e-7,re=e-7'
      \ . ' contains=goTodo,@Spell'
      \ . (s:has_setting('fold-pkg-comment') ? ' fold' : '')

" Link
hi def link goPackage             Statement
hi def link goImport              Statement
hi def link goVar                 Keyword
hi def link goConst               Keyword
hi def link goDeclaration         Keyword

hi def link goStatement           Statement
hi def link goConditional         Conditional
hi def link goLabel               Label
hi def link goRepeat              Repeat

hi def link goType                Type
hi def link goBuiltins            Keyword
hi def link goBoolean             Boolean

hi def link goComment             Comment
hi def link goTodo                Todo

hi def link goGenerateKW          Special
hi def link goGenerateVars        Special

hi def link goCompilerDir         Special

hi def link goBuildTagStart       Comment
hi def link goStdBuildTags        Special
hi def link goVersionBuildTags    Special
hi def link goBuildKeyword        Special

hi def link goEscapeOctal         goSpecialString
hi def link goEscapeC             goSpecialString
hi def link goEscapeX             goSpecialString
hi def link goEscapeU             goSpecialString
hi def link goEscapeBigU          goSpecialString
hi def link goSpecialString       Special
hi def link goEscapeError         Error

hi def link goFormatSpecifier     goSpecialString

hi def link goString              String
hi def link goRawString           String
hi def link goStructTagName       Keyword

hi def link goCharacter           Character

hi def link goDecimalInt          Integer
hi def link goHexadecimalInt      Integer
hi def link goOctalInt            Integer
hi def link goOctalError          Error
hi def link Integer               Number

hi def link goFloat               Float

hi def link goImaginary           Number
hi def link goImaginaryFloat      Float

hi def link goPackageComment      Comment

" Search backwards for a global declaration to start processing the syntax.
syn sync match goSync grouphere NONE /\v^(const|var|type|func)>/

let b:current_syntax = 'go'

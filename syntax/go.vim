if exists('b:current_syntax')
  finish
endif

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

" Predefined identifiers.
syn keyword     goType            chan map bool string error
syn keyword     goType            int int8 int16 int32 int64 rune
syn keyword     goType            byte uint uint8 uint16 uint32 uint64 uintptr
syn keyword     goType            float32 float64
syn keyword     goType            complex64 complex128
syn keyword     goBuiltins        append cap close complex copy delete imag len
syn keyword     goBuiltins        make new panic print println real recover
syn keyword     goBoolean         true false nil iota

" Comments blocks.
syn keyword     goTodo            contained TODO FIXME XXX BUG
syn region      goComment         start="//" end="$"    contains=goCompilerDir,goGenerate,goBuildTag,goTodo,@Spell

if s:has_setting('fold-comment')
  syn region    goComment         start="/\*" end="\*/" contains=goTodo,@Spell fold
  syn match     goComment         "\v(^\s*//.*\n)+"     contains=goCompilerDir,goGenerate,goBuildTag,goTodo,@Spell fold
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
syn match       goCompilerDir     display contained
      \ "\v^//go:(nointerface|noescape|norace|nosplit|noinline|systemstack|nowritebarrier|nowritebarrierrec|yeswritebarrierrec|cgo_unsafe_args|uintptrescapes|notinheap)$"

" Build tags; standard build tags from cmd/dist/build.go and go doc go/build.
syn match   goBuildKeyword        display contained "+build"
syn keyword goStdBuildTags        contained
      \ 386 amd64 amd64p32 arm arm64 mips mipsle mips64 mips64le ppc64 ppc64le
      \ riscv64 s390x wasm darwin dragonfly js linux android solaris freebsd
      \ nacl netbsd openbsd plan9 windows gc gccgo cgo race
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
        \v%(%(%([\d+])?\*)|\d+)?\m\
        \v%(\.%(%(%([\d+])?\*)|\d+)?)?\m\
        \v%([\d+])?[vTtbcdoqxXUeEfFgGsp]\m/ contained containedin=goString,goRawString
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
syn match       goSingleDecl      /\(import\|var\|const\) [^(]\@=/ contains=goImport,goVar,goConst

"
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

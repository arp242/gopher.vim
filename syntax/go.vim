if exists('b:current_syntax')
  finish
endif

" The ftplugin is loaded after the syntax file, so load it here too.
call gopher#init#config()
let s:has = { n -> index(g:gopher_highlight, l:n) > -1 }

" Match case.
syn case match

" Search backwards for a global declaration to start processing the syntax.
syn sync match goSync grouphere NONE /\v^%(const|var|type|func)>/

" Still keep 'minlines' here since otherwise it tends to break with multiline
" comment blocks and `-strings where the opening is beyond the screen:
"
"     const x = `
"        [.. many lines ..]
"     `
"
"     func foo() {
"         [.. code .. ]
"         [ cursor here, opening ` out of screen ]
"     }
"
" It will sync to ^func, the opening ` is out of the screen and sees just the
" closing, so everything is highlighted as a string.
"
" I'm not sure if there's a better solution for this.
syn sync minlines=200


" Keywords.
syn keyword     goPackage      package
syn keyword     goImport       import    contained
syn keyword     goVar          var       contained
syn keyword     goConst        const     contained
syn keyword     goStruct       struct    contained
syn keyword     goDeclaration  func type interface
syn keyword     goStatement    defer go goto return break continue fallthrough
syn keyword     goConditional  if else switch select
syn keyword     goLabel        case default
syn keyword     goRepeat       for range
syn keyword     goBoolean      true false nil iota

" Predefined types.
syn keyword     goType      chan map bool string error float32 float64 complex64 complex128
syn keyword     goType      int int8 int16 int32 int64 rune byte uint uint8 uint16 uint32 uint64 uintptr
syn keyword     goBuiltins  append cap close complex copy delete imag len
syn keyword     goBuiltins  make new panic print println real recover

" Comment blocks.
syn keyword     goTodo      contained TODO FIXME XXX BUG
syn region      goComment   start="//" end="$"    contains=goCompilerDir,goGenerate,goDirectiveError,goBuildTag,goTodo,@Spell

if s:has('fold-comment')
  syn region    goComment   start="/\*" end="\*/" contains=goTodo,@Spell fold
  syn match     goComment   "\v%(^\s*//.*\n)+"     contains=goCompilerDir,goGenerate,goDirectiveError,goBuildTag,goTodo,@Spell fold
else
  syn region    goComment   start="/\*" end="\*/" contains=goTodo,@Spell
endif

" go:generate; see go help generate
syn match       goGenerateKW      display contained /go:generate/
syn match       goGenerateVars    contained /\v\$(GOARCH|GOOS|GOFILE|GOLINE|GOPACKAGE|DOLLAR)/
syn region      goGenerate        excludenl contained matchgroup=goGenerateKW start="^//go:generate" end=/$/ contains=goGenerateVars,goGenerateKW

" Compiler directives.
" https://golang.org/cmd/compile/#hdr-Compiler_Directives
" pragmaValue in cmd/compile/internal/gc/lex.go
" TODO: //go:linkname localname importpath.name
" TODO: support line directives.
syn match       goCompilerDir     excludenl display contained "\v^//go:%(nointerface|noescape|norace|nosplit|noinline|systemstack|nowritebarrier|nowritebarrierrec|yeswritebarrierrec|cgo_unsafe_args|uintptrescapes|notinheap)$"

" Adding a space between the // and go: is an error.
syn match      goDirectiveError  excludenl contained "^// go:.\+$"

" Build tags; standard build tags from cmd/dist/build.go and go doc go/build.
syn match   goBuildKeyword        display contained "+build"
syn keyword goStdBuildTags        contained
      \ 386 amd64 amd64p32 arm arm64 mips mipsle mips64 mips64le ppc ppc64 ppc64le
      \ riscv64 s390x wasm darwin dragonfly hurd js linux android solaris
      \ freebsd nacl netbsd openbsd plan9 windows gc gccgo cgo race
syn match   goVersionBuildTags    contained /\v<go1\.[0-9]{1,2}>[^.]/

" The rs=s+2 option lets the \s*+build portion be part of the inner region
" instead of the matchgroup so it will be highlighted as a goBuildKeyword.
syn region  goBuildTag            contained matchgroup=goBuildTagStart
      \ start="^//\s*+build\s"rs=s+2 end="$"
      \ contains=goBuildKeyword,goStdBuildTags,goVersionBuildTags

" cgo
syn match goCgoError contained containedin=goComment "^\%(\/\/\)\?\s*#cgo .*"
syn match goCgoError contained containedin=goComment "^\%(\/\/\)\?\s*#\s*include .*"

syn match goCgo contained containedin=goComment "//export \i\+"
syn match goCgo contained containedin=goComment /^\%(\/\/\)\?\s*#\s*include [<"]\f\+\.h[>"]/
syn match goCgo contained containedin=goComment /\v^%(\/\/)?\s*#\s*%(ifdef \w+|ifndef \w+|else|endif)/
syn match goCgo contained containedin=goComment /\v^%(\/\/)?\s*#cgo pkg-config:%( \f+)+/
syn match goCgo contained containedin=goComment /\v^%(\/\/)?\s*#cgo
      \ %(!?%(386|amd64|amd64p32|arm|arm64|mips|mipsle|mips64|mips64le|ppc|ppc64|ppc64le|riscv64|s390x|wasm|darwin|dragonfly|hurd|js|linux|android|solaris|freebsd|nacl|netbsd|openbsd|plan9|windows|gc|gccgo)[, ]*)*
      \%(CFLAGS|CPPFLAGS|CXXFLAGS|FFLAGS|LDFLAGS):.+/

" String escapes.
syn match       goEscapeOctal     display contained "\\[0-7]\{3}"
syn match       goEscapeC         display contained +\\[abfnrtv\\'"]+
syn match       goEscapeX         display contained "\\x\x\{2}"
syn match       goEscapeU         display contained "\\u\x\{4}"
syn match       goEscapeBigU      display contained "\\U\x\{8}"
syn match       goEscapeError     display contained +\\[^0-7xuUabfnrtv\\'"]+
syn cluster     goStringGroup     contains=goEscapeOctal,goEscapeC,goEscapeX,goEscapeU,goEscapeBigU,goEscapeError

" Strings
if s:has('string-spell')
  syn region    goString          start=/"/ end=/"/ contains=@goStringGroup,@Spell
  syn region    goRawString       start=/`/ end=/`/ contains=@Spell
else
  syn region    goString          start=/"/ end=/"/ contains=@goStringGroup
  syn region    goRawString       start=/`/ end=/`/
endif

" Structs and struct tags.
" TODO: also highlight attributes: 'omitempty' in `json:"foo,omitempty"`
" TODO: also highlight lack of quote, and attr space error: `json:foo, omitempty`
syn region      goStruct          start=/struct {/ end=/}/ transparent containedin=goBlock contains=ALLBUT,goParen,goBlock
syn match       goStructTag       / `.*`$/ containedin=goStruct
syn match       goStructTagError  /\w\{-1,} *: *"/he=e-2 contained containedin=goStructTag
syn match       goStructTagName   /\w\{-1,}:\ze"/ contained containedin=goStruct,goStructTag

if s:has('string-fmt')
  " TODO: this is a bit slow, but can't seem ot make it faster. Not sure if it's
  " possible.
  "
  " % not preceded by a %, followed by any of [-#0+ ]
  " * or [n]* or any number or nothing before a .
  " * or [n]* or any number or nothing after a .
  " [n] or nothing before a verb
  " formatting verb
  syn match       goFormatSpecifier  contained containedin=goString,goRawString /\
        \%([^%]\(%%\)*\)\
        \@<=%[-#0 +]*\
        \v%(%(%(\[\d+])?\*)|\d+)?\
        \v%(\.%(%(%(\[\d+])?\*)|\d+)?)?\
        \v%(\[\d+])?[vTtbcdoOqxXUeEfFgGspw]/
endif

" Character.
syn cluster     goCharacterGroup  contains=goEscapeOctal,goEscapeC,goEscapeX,goEscapeU,goEscapeBigU
syn region      goCharacter       start=/'/ end=/'/ contains=@goCharacterGroup

" Regions
syn region      goParen           start='(' end=')' transparent
if s:has('fold-block')
  syn region    goBlock           start="{" end="}" transparent fold
else
  syn region    goBlock           start="{" end="}" transparent
endif

" import
if s:has('fold-import')
  syn region    goImport          start='import (' end=')' transparent fold contains=goImport,goString,goComment
else
  syn region    goImport          start='import (' end=')' transparent contains=goImport,goString,goComment
endif

" var, const
if s:has('fold-varconst')
  syn region    goVar             start='var ('   end='^\s*)$' transparent fold contains=ALLBUT,goParen,goBlock
  syn region    goConst           start='const (' end='^\s*)$' transparent fold contains=ALLBUT,goParen,goBlock
else
  syn region    goVar             start='var ('   end='^\s*)$' transparent contains=ALLBUT,goParen,goBlock,goStructTag,goStructTagError
  syn region    goConst           start='const (' end='^\s*)$' transparent contains=ALLBUT,goParen,goBlock
endif

" Single-line var, const, and import.
"
"   ^\s*\zs                  Set match start after any leading whitespace.
"   %(import|var|const)      Keywords
"   \ze                      Set end of match.
"    [^)]                    Don't match if followed by " (", to prevent
"                            conflict with go{Var,Const,Import} so it can fold
syn match       goSingleDecl       /\v^\s*\zs%(import|var|const)\ze [^(]/    contains=goImport,goVar,goConst

" Numbers.
"
"   -?            # Optional -
"   <             # Word boundary
"   [0-9_]+       # Any amount of digits and underscores.
"   %(
"      e          # Optionally match exponent part of scientific notation.
"      [-+]?
"      [0-9_]+
"   )?
syn match       goDecimalInt      /\v\c<[0-9][0-9_]*%(e[-+]?[0-9_]+)?>/
syn match       goHexadecimalInt  /\v\c<0x[0-9a-f_]+>/
syn match       goOctalInt        /\v\c<0o?[0-7_]+>/
syn match       goBinaryInt       /\v\c<0b[01_]+>/

syn match       goOctalError      /\v\c<0o?[0-7_]*[89]+[0-9_]*>/
syn match       goBinaryError     /\v\c<0b[01_]*[2-9]+[0-9_]*>/
syn match       goHexError        /\v\c<0x[0-9a-f_]*[g-z]+[0-9a-f_]*>/

" Floating points.
" The first one matches '0.6', the second '.6'; it's about a third faster to do
" this in 2 regexps.
syn match       goFloat           /\v\c<[0-9_]+\.[0-9_]*%(e[-+]?[0-9_]+)?>/
syn match       goFloat           /\v\c\.[0-9_]+%(e[-+]?[0-9_]+)?>/

" Complex numbers.
if s:has('complex')
  syn match     goImaginary       /\v\c<[0-9_]+i>/
  syn match     goImaginary       /\v\c<[0-9_]+e[-+]?[0-9_]+i>/
  syn match     goImaginaryFloat  /\v\c<[0-9_]+\.[0-9_]*%(e[-+]?[0-9_]+)?i>/
  syn match     goImaginaryFloat  /\v\c<\.[0-9_]+%(e[-+]?[0-9_]+)?i>/
endif

" One or more line comments that are followed immediately by a "package"
" declaration are treated like package documentation, so these must be
" matched as comments to avoid looking like working build constraints.
" The he, me, and re options let the "package" itself be highlighted by
" the usual rules.
if s:has('fold-pkg-comment')
  " TODO: runs out of memory in mattn/go-gtk
  syn region  goPackageComment fold contains=goTodo,@Spell
                             \ start=/\v%(\/\/.*\n)+\s*package/
                             \ end=/\v\n\s*package/he=e-7,me=e-7,re=e-7

  syn region  goPackageComment fold contains=goTodo,@Spell
                             \ start=/\v^\s*\/\*.*\n%(.*\n)*\s*\*\/\npackage/
                             \ end=/\v\*\/\n\s*package/he=e-7,me=e-7,re=e-7
endif

" Link
hi def link goPackage             Statement
hi def link goImport              Statement
hi def link goVar                 Keyword
hi def link goConst               Keyword
hi def link goStruct              Keyword
hi def link goDeclaration         Keyword

hi def link goStatement           Statement
hi def link goConditional         Conditional
hi def link goLabel               Label
hi def link goRepeat              Repeat

hi def link goType                Type
hi def link goBuiltins            Keyword
hi def link goBoolean             Boolean

hi def link goComment             Comment
hi def link goPackageComment      Comment
hi def link goTodo                Todo

hi def link goGenerateKW          Special
hi def link goGenerateVars        Special

hi def link goCompilerDir         Special
hi def link goDirectiveError      Error

hi def link goBuildTagStart       Comment
hi def link goStdBuildTags        Special
hi def link goVersionBuildTags    Special
hi def link goBuildKeyword        Special
hi def link goCgo                 Special
hi def link goCgoError            Error

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
hi def link goStructTag           goRawString
hi def link goStructTagName       Keyword
hi def link goStructTagError      Error

hi def link goCharacter           Character

hi def link goDecimalInt          Integer
hi def link goHexadecimalInt      Integer
hi def link goOctalInt            Integer
hi def link goBinaryInt           Integer
hi def link goOctalError          Error
hi def link goBinaryError         Error
hi def link goHexError            Error
hi def link Integer               Number

hi def link goFloat               Float

hi def link goImaginary           Number
hi def link goImaginaryFloat      Float

let b:current_syntax = 'go'

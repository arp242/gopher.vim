" vint: -ProhibitUnnecessaryDoubleQuote

if exists('g:current_compiler')
  finish
endif
let g:current_compiler = 'gotest'
let s:save_cpo = &cpoptions
set cpoptions-=C

" CompilerSet makeprg=go\ test
let &l:makeprg = 'go test ' . gopher#system#join(get(g:, 'gopher_build_flags', []))

let s:goroot = system('go env s:goroot')[:-2]

""" vim-go """
" https://github.com/fatih/vim-go/blob/master/autoload/go/test.vim
" :%s/\<goroot\>/s:goroot/
" :%s/\<indent\>/s:indent/
" :%s/let format/let \&l:errorformat/:%s/let format/let \&l:errorformat/


" each level of test indents the test output 4 spaces. Capturing groups
" (e.g. \(\)) cannot be used in an errorformat, but non-capturing groups can
" (e.g. \%(\)).
let s:indent = '%\\%(    %\\)'

" ignore `go test -v` output for starting tests
let &l:errorformat = '%-G=== RUN   %.%#'
" ignore `go test -v` output for passing tests
let &l:errorformat .= ',%-G' . s:indent . '%#--- PASS: %.%#'

" Match failure lines.

" Example failures start with '--- FAIL: ', followed by the example name
" followed by a space , followed by the duration of the example in
" parantheses. They aren't nested, though, so don't check for indentation.
" The errors from them also aren't indented and don't report file location
" or line numbers, so those won't show up. This will at least let the user
" know which example failed, though.
let &l:errorformat .= ',%G--- FAIL: %\\%(Example%\\)%\\@=%m (%.%#)'

" Test failures start with '--- FAIL: ', followed by the test name followed
" by a space, followed by the duration of the test in parentheses.
"
" e.g.:
"   '--- FAIL: TestSomething (0.00s)'
let &l:errorformat .= ',%G' . s:indent . '%#--- FAIL: %m (%.%#)'

" Go 1.10 test output {{{1
" Matches test output lines.
"
" All test output lines start with the test indentation and a tab, followed
" by the filename, a colon, the line number, another colon, a space, and the
" message. e.g.:
"   '\ttime_test.go:30: Likely problem: the time zone files have not been installed.'
let &l:errorformat .= ',%A' . s:indent . "%#%\\t%\\+%f:%l: %m"
" also match lines that don't have a message (i.e. the message begins with a
" newline or is the empty string):
" e.g.:
"     t.Errorf("\ngot %v; want %v", actual, expected)
"     t.Error("")
let &l:errorformat .= ',%A' . s:indent . "%#%\\t%\\+%f:%l: "

" Match the 2nd and later lines of multi-line output. These lines are
" indented the number of spaces for the level of nesting of the test,
" followed by two tabs, followed by the message.
"
" Treat these lines as if they are stand-alone lines of output by using %G.
" It would also be valid to treat these lines as if they were the
" continuation of a multi-line error by using %C instead of %G, but that
" would also require that all test errors using a %A or %E modifier to
" indicate that they're multiple lines of output, but in that case the lines
" get concatenated in the quickfix list, which is not what users typically
" want when writing a newline into their test output.
let &l:errorformat .= ',%G' . s:indent . "%#%\\t%\\{2}%m"
" }}}1
 
" work with 1.14 'go test -v'
let &l:errorformat .= ',%A' . s:indent . "%\\+%[%^:]%\\+: %f:%l: %m"
let &l:errorformat .= ',%A' . s:indent . "%\\+%[%^:]%\\+: %f:%l: "

" Go 1.11 test output {{{1
" Match test output lines similarly to Go 1.10 test output lines, but they
" use an s:indent level where the Go 1.10 test output uses tabs, so they'll
" always have at least one level indentation...
let &l:errorformat .= ',%A' . s:indent . "%\\+%f:%l: %m"
let &l:errorformat .= ',%A' . s:indent . "%\\+%f:%l: "
let &l:errorformat .= ',%G' . s:indent . "%\\{2\\,}%m"
" }}}1

" set the format for panics.

" handle panics from test timeouts
let &l:errorformat .= ",%+Gpanic: test timed out after %.%\\+"

" handle non-timeout panics
" In addition to 'panic', check for 'fatal error' to support older versions
" of Go that used 'fatal error'.
"
" Panics come in two flavors. When the goroutine running the tests panics,
" `go test` recovers and tries to exit more cleanly. In that case, the panic
" message is suffixed with ' [recovered]'. If the panic occurs in a
" different goroutine, it will not be suffixed with ' [recovered]'.
let &l:errorformat .= ',%+Afatal error: %.%# [recovered]'
let &l:errorformat .= ',%+Apanic: %.%# [recovered]'
let &l:errorformat .= ',%+Afatal error: %.%#'
let &l:errorformat .= ',%+Apanic: %.%#'

" Match address lines in stacktraces produced by panic.
"
" Address lines in the stack trace have leading tabs, followed by the path
" to the file. The file path is followed by a colon and then the line number
" within the file where the panic occurred. After that there's a space and
" hexadecimal number.
"
" e.g.:
"   '\t/usr/local/go/src/time.go:1313 +0x5d'

" panicaddress and readyaddress are identical except for
" panicaddress sets the filename and line number.
let s:panicaddress = "%\\t%f:%l +0x%[0-9A-Fa-f]%\\+"
let s:readyaddress = "%\\t%\\f%\\+:%\\d%\\+ +0x%[0-9A-Fa-f]%\\+"
" stdlib address is identical to readyaddress, except it matches files
" inside s:goroot.
let s:stdlibaddress = "%\\t" . s:goroot . "%\\f%\\+:%\\d%\\+ +0x%[0-9A-Fa-f]%\\+"

" Match and ignore the running goroutine line.
let &l:errorformat .= ",%-Cgoroutine %\\d%\\+ [running]:"
" Match address lines that refer to stdlib, but consider them informational
" only. This is to catch the lines after the first address line in the
" running goroutine of a panic stack trace. Ideally, this wouldn't be
" necessary, but when a panic happens in the goroutine running a test, it's
" recovered and another panic is created, so the stack trace actually has
" the line that caused the original panic a couple of addresses down the
" stack.
let &l:errorformat .= ',%-C' . s:stdlibaddress
" Match address lines in the first matching goroutine. This means the panic
" message will only be shown as the error message in the first address of
" the running goroutine's stack.
let &l:errorformat .= ',%Z' . s:panicaddress

" Match and ignore errors from runtime.goparkunlock(). These started
" appearing in stack traces from Go 1.12 test timeouts.
let &l:errorformat .= ',%-Gruntime.goparkunlock(%.%#'
let &l:errorformat .= ",%-G%\\t" . s:goroot . "%\\f%\\+:%\\d%\\+"

" Match and ignore panic address without being part of a multi-line message.
" This is to catch those lines that come after the top most non-standard
" library line in stack traces.
let &l:errorformat .= ',%-G' . s:readyaddress

" Match and ignore exit status lines (produced when go test panics) whether
" part of a multi-line message or not, because these lines sometimes come
" before and sometimes after panic stacktraces.
let &l:errorformat .= ",%-Cexit status %[0-9]%\\+"
"let &l:errorformat .= ",exit status %[0-9]%\\+"

" Match and ignore failure lines whether part of a multi-line message
" or not, because these lines sometimes come before and sometimes after
" panic stacktraces.
let &l:errorformat .= ",%-CFAIL%\\t%.%#"
"let &l:errorformat .= ",FAIL%\\t%.%#"

" match compiler errors.
" These are very smilar to errors from <=go1.10 test output, but lack
" leading tabs for the first line of an error, and subsequent lines only
" have one tab instead of two.
let &l:errorformat .= ",%A%f:%l:%c: %m"
let &l:errorformat .= ",%A%f:%l: %m"
" It would be nice if this weren't necessary, but panic lines from tests are
" prefixed with a single leading tab, making them very similar to 2nd and
" later lines of a multi-line compiler error. Swallow it so that it doesn't
" cause a quickfix entry since the next %G entry can add a quickfix entry
" for 2nd and later lines of a multi-line compiler error.
let &l:errorformat .= ",%-C%\\tpanic: %.%#"
let &l:errorformat .= ",%G%\\t%m"

" Match and ignore everything else in multi-line messages.
let &l:errorformat .= ',%-C%.%#'
" Match and ignore everything else not in a multi-line message:
let &l:errorformat .= ',%-G%.%#'

""" vim-go end """

let &cpoptions = s:save_cpo
unlet s:save_cpo

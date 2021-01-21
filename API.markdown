
Public API for gopher.vim. This is not stable yet!

This file is generated using the mkapi script

[gopher.vim](autoload/gopher.vim)
---------------------------------
Various common functions, or functions that don't have a place elsewhere.

    gopher#error(msg, ...)
      Output an error message to the screen. The message can be either a list or a
      string; every line will be echomsg'd separately.

    gopher#info(msg, ...)
      Output an informational message to the screen. The message can be either a
      list or a string; every line will be echomsg'd separately.

    gopher#has_debug(flag)
      Report if the user enabled the given debug flag.

    gopher#bufsetting(name, default)
      Get a buffer-local b:gopher_ setting, falling back to the g: one if it's
      undefined, and returning a:default if that's undefined too.

    gopher#override_vimgo()
      Override vim-go.


[coverage.vim](autoload/gopher/coverage.vim)
--------------------------------------------
Implement :GoCoverage.

    gopher#coverage#complete(lead, cmdline, cursor)
      Complete the special flags and some common flags people might want to use.

    gopher#coverage#do(...)
      Apply or clear coverage highlights.

    gopher#coverage#is_visible()
      Report if the coverage display is currently visible.

    gopher#coverage#clear_hi(winid)
      Clear any existing highlights for the given window ID, or the current window
      if 0.

    gopher#coverage#stop()
      Stop coverage mode.


[pkg.vim](autoload/gopher/pkg.vim)
----------------------------------
Utilities for working with Go packages.

    gopher#pkg#list_importable()
      List all 'importable' packages; this is the stdlib + GOPATH or modules.

    gopher#pkg#list_interfaces(pkg)
      List all interfaces for a Go package.


[init.vim](autoload/gopher/init.vim)
------------------------------------
Initialisation of the plugin.

    gopher#init#version()
      Check if the requires Vim/Neovim/Go versions are installed.

    gopher#init#version_check(v)
      Check if the 'go version' output is a version we support.

    gopher#init#config()
      Initialize config values.


[compl.vim](autoload/gopher/compl.vim)
--------------------------------------
Some helpers to work with commandline completion.

    gopher#compl#filter(lead, list)
      Return a copy of the list with only the items starting with lead.

    gopher#compl#word(cmdline, cursor)
      Get the current word that's being completed.

    gopher#compl#prev_word(cmdline, cursor)
      Get the previous word.


[present.vim](autoload/gopher/present.vim)
------------------------------------------
Implement support for go present slides.

    gopher#present#jump(mode, dir)
      Jump to the next or previous section.
      mode can be 'n', 'o', or 'v' for normal, operator-pending, or visual mode.
      dir can be 'next' or 'prev'.


[tags.vim](autoload/gopher/tags.vim)
------------------------------------
Implement :GoTags.

    gopher#tags#complete(lead, cmdline, cursor)
      Complete flags and common tags.

    gopher#tags#modify(start, end, count, ...)
      Modify tags.


[win.vim](autoload/gopher/win.vim)
----------------------------------
Utilities for working with windows.

    gopher#win#list()
      Get a list of all Go window IDs for all tabs.


[qf.vim](autoload/gopher/qf.vim)
--------------------------------
Utilities for working with the quickfix and location list.

    gopher#qf#populate(out, efm, title)
      Populate the quickfix list with the errors from out, parsed according to the
      errorformat in efm.
      If efm is an empty string "%f:%l:%c %m" will be used.


[motion.vim](autoload/gopher/motion.vim)
----------------------------------------
Implement motions and text objects.

    gopher#motion#jump(mode, dir)
      Jump to the next or previous top-level declaration.
      mode can be 'n', 'o', or 'v' for normal, operator-pending, or visual mode.
      dir can be 'next' or 'prev'.

    gopher#motion#comment(mode)
      Select current comment block.
      mode can be 'a' or 'i', for the 'ac' and 'ic' variants.

    gopher#motion#function(mode)
      Select the current function.
      mode can be 'a' or 'i', for the 'af' and 'if' variants.


[dict.vim](autoload/gopher/dict.vim)
------------------------------------
Utilities for working with dictionaries.

    gopher#dict#merge(defaults, override)
      Merge two dictionaries, also recursively merging nested keys.
      Use extend() if you don't need to merge nested keys.


[system.vim](autoload/gopher/system.vim)
----------------------------------------
Utilities for working with the external programs and the OS.

    gopher#system#setup()
      Setup modules and install all tools.

    gopher#system#history()
      Get command history (only populated if 'commands' is in the g:gopher_debug)
      variable. Note that the list is reversed (new entries are prepended, not
      appended).

    gopher#system#clear_history()
      Clear command history.

    gopher#system#jobs()
      Get a list of currently running jobs. Use job_info() to get more information
      about a job.

    gopher#system#restore_env(name, val)
      Restore an environment variable back to its original value.

    gopher#system#tmpmod()
      Write unsaved buffer to a temp file when modified, so tools that operate on
      files can use that.
      The first return value is either the tmp file or the full path to the original
      file (if not modified), the second return value signals that this is a tmp
      file.
      Don't forget to delete the tmp file!

    gopher#system#archive()
      Format the current buffer as an 'overlay archive':
      https://godoc.org/golang.org/x/tools/go/buildutil#ParseOverlayArchive

    gopher#system#tool(cmd, ...)
      Run a known Go tool.

    gopher#system#tool_job(done, cmd)
      Run a known Go tool in the background.

    gopher#system#run(cmd, ...)
      Run an external command.
      cmd must be a list, one argument per item. Every list entry will be
      automatically shell-escaped
      An optional second argument is passed to stdin.

    gopher#system#job(done, cmd)
      Start a simple async job.
      cmd    Command as list.
      done   Callback function, called with the arguments:
      exit  exit code
      out   stdout and stderr output as string, interleaved in correct
      order (hopefully).
      TODO: Don't run multiple jobs that modify the buffer at the same time. For
      some tools (like gorename) we need a global lock.

    gopher#system#job_wait(job)
      Wait for a job to finish. Note that the exit_cb or close_cb may still be
      running after this returns!
      It will return the job status ("fail" or "dead").

    gopher#system#pathsep()
      Get the path separator for this platform.

    gopher#system#join(l, ...)
      Join a list of commands to a string, escaping any shell meta characters.

    gopher#system#sanitize_cmd(cmd)
      Remove v:null from the command, makes it easier to build commands:
      gopher#system#run(['gosodoff', (a:error ? '-errcheck' : v:null)])
      Without the filter an empty string would be passed.

    gopher#system#store_cache(val, name, ...)
      Store data in the cache.

    gopher#system#cache(name, ...)
      Retrieve data from the cache.

    gopher#system#closest(name)
      Get the closest directory with this name up the tree from the current buffer's
      path.
      /a/b/c   c → /a/b/c
      /a/b/c   a → /a
      /a/b/c   x → (empty string)


[str.vim](autoload/gopher/str.vim)
----------------------------------
Utilities for working with strings.

    gopher#str#has_prefix(s, prefix)
      Report if s begins with prefix.

    gopher#str#has_suffix(s, suffix)
      Report if s ends with suffix.

    gopher#str#escape(s)
      Escape a user-provided string so it can be safely used in regexps.
      NOTE: this only works with the default value of 'magic'!

    gopher#str#url_encode(s)
      URL encode a string.

    gopher#str#fold_space(s)
      Fold multiple whitespace to a single space.


[list.vim](autoload/gopher/list.vim)
------------------------------------
Utilities for working with lists.

    gopher#list#flatten(l)
      Flatten a list.


[rename.vim](autoload/gopher/rename.vim)
----------------------------------------
Implement :GoRename.

    gopher#rename#complete(lead, cmdline, cursor)
      Commandline completion: original, unexported camelCase, and exported
      CamelCase.

    gopher#rename#do(...)
      Rename the identifier under the cursor to the identifier in the first
      argument.


[guru.vim](autoload/gopher/guru.vim)
------------------------------------
implement the :GoGuru command.

    gopher#guru#complete(lead, cmdline, cursor)


    gopher#guru#do(...)



[buf.vim](autoload/gopher/buf.vim)
----------------------------------
Utilities for working with buffers.

    gopher#buf#lines()
      Get all lines in the buffer as a list.

    gopher#buf#list()
      Get a list of all Go bufnrs.

    gopher#buf#doall(cmd)
      Run a command on every Go buffer and restore the position to the active
      buffer.

    gopher#buf#write_all()
      Save all unwritten Go buffers.

    gopher#buf#cursor(...)
      Returns the byte offset for the cursor.
      If the first argument is non-blank it will return filename:#offset

    gopher#buf#replace(start, end, data)
      Replace text from byte offset 'start' to offset 'end'.


[go.vim](autoload/gopher/go.vim)
--------------------------------
Utilities for working with Go files.

    gopher#go#is_test()
      Report if the current buffer is a Go test file.

    gopher#go#in_gopath()
      Report if the current buffer is inside GOPATH.

    gopher#go#module()
      Get the Go module name, or -1 if there is none.

    gopher#go#package()
      Get the package path for the file in the current buffer.

    gopher#go#packagepath()
      Get path to file in current buffer as package/path/file.go

    gopher#go#add_build_tags(flag_list)
      Add b:gopher_build_tags or g:gopher_build_tags to the flag_list; will be
      merged with existing tags (if any).

    gopher#go#find_build_tags()
      Find the build tags for the current buffer; returns a list (or empty list if
      there are none).

    gopher#go#set_build_package()
      Set b:gopher_build_package to ./cmd/[module-name] if it exists.

    gopher#go#set_build_tags()
      Set b:gopher_build_tags to the build tags in the current buffer.

    gopher#go#current_function()
      Get the function name the cursor is in; the return value is a list where the
      first item is the full name and the second one is the full signature minus
      'func':
      func foo()                → ['foo', 'foo()']
      func foo(x int) int       → ['foo', 'foo(x int) int']
      func (t T) foo(x int) int → ['T.foo', '(t T) foo(x int) int']
      Returns ['', ''] if there is no function.

    gopher#go#current_test(run)
      Get the current test name as ['TestFoo'), or an empty list if the cursor isn't
      inside a test function.
      If a:run is non-0 it will return the name as ['-run', '^TestFoo$'], for
      passing to a 'go test' command.

    gopher#go#run_install()
      Run the go compiler.

    gopher#go#run_test()
      Run go test for the current package.

    gopher#go#run_test_current()
      Run go test for the current function.

    gopher#go#run_lint()
      Run lint tool for the current package.


[import.vim](autoload/gopher/import.vim)
----------------------------------------
Implement :GoImport

    gopher#import#complete(lead, cmdline, cursor)
      Complete package names.

    gopher#import#do(...)
      Add, modify, or remove imports.


[diag.vim](autoload/gopher/diag.vim)
------------------------------------
Implement :GoDiag.

    gopher#diag#complete(lead, cmdline, cursor)
      Completion for :GoDiag

    gopher#diag#do(to_clipboard, ...)
      Get diagnostic information about gopher.vim


[frob.vim](autoload/gopher/frob.vim)
------------------------------------
Modify Go code.

    gopher#frob#cmd(...)
      Run the :GoFrob command.

    gopher#frob#complete(lead, cmdline, cursor)
      Complete the mappings people can choose and interfaces for 'implement'.

    gopher#frob#implement(iface)
      Implement methods for an interface.

    gopher#frob#if()
      Toggle between 'single-line' and 'normal' if checks:
      err := e()
      if err != nil {
      and:
      if err := e(); err != nil {
      This works for all variables, not just error checks.

    gopher#frob#ret(error)
      Generate a return statement with zero values.
      If error is 1 it will return 'err' and surrounded in an 'if err != nil' check.

    gopher#frob#fillstruct()
      Fill a struct.

    gopher#frob#popup()
      Show a popup menu with mappings to choose from.
      TODO: move out of frob.vim to popup.vim, since it's more than just frob
      commands now.



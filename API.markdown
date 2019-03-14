
Public API for gopher.vim. This is not stable yet!

This file is generated using the mkapi script

[gopher.vim](autoload/gopher.vim)
----------

    gopher#has_debug(flag)
      Report if the user enabled a debug flag.

    gopher#info(msg, ...)
      Output an informational message to the screen. The message can be either a
      list or a string; every line will be echomsg'd separately.

    gopher#error(msg, ...)
      Output an error message to the screen. The message can be either a list or a
      string; every line will be echomsg'd separately.


[motion.vim](autoload/gopher/motion.vim)
----------

    gopher#motion#comment(mode)
      Select current comment block.

    gopher#motion#jump(mode, dir)
      Jump to the next or previous top-level declaration.
      mode can be 'n', 'o', or 'v' for normal, operator-pending, or visual mode.
      dir can be 'next' or 'prev'.


[buf.vim](autoload/gopher/buf.vim)
-------

    gopher#buf#cursor(...)
      Returns the byte offset for the cursor.
      If the first argument is non-blank it will return filename:#offset

    gopher#buf#write_all()
      Save all unwritten Go buffers.

    gopher#buf#doall(cmd)
      Run a command on every Go buffer and restore the position to the active
      buffer.

    gopher#buf#list()
      Get a list of all Go bufnrs.

    gopher#buf#lines()
      Get all lines in the buffer as a a list.


[rename.vim](autoload/gopher/rename.vim)
----------

    gopher#rename#do(...)



[coverage.vim](autoload/gopher/coverage.vim)
------------

    gopher#coverage#clear()
      Clear any existing highlights.

    gopher#coverage#is_visible()
      Report if the coverage display is currently visible.

    gopher#coverage#do(...)
      Apply or clear coverage highlights.

    gopher#coverage#complete(lead, cmdline, cursor)
      Complete the special flags and some common flags people might want to use.


[str.vim](autoload/gopher/str.vim)
-------

    gopher#str#escape(s)
      Escape a user-provided string so it can be safely used in regexps.
      NOTE: this only works with the default value of 'magic'!

    gopher#str#has_suffix(s, suffix)
      Report if s ends with suffix.

    gopher#str#has_prefix(s, prefix)
      Report if s begins with prefix.

    gopher#str#trim(s, cutset)
      Trim leading and trailing instances of all characters in cutset.
      Note that the curset characters need to be regexp-escaped!

    gopher#str#trim_space(s)
      Trim leading and trailing whitespace from a string.


[present.vim](autoload/gopher/present.vim)
-----------

    gopher#present#jump(mode, dir)
      Jump to the next or previous section.
      mode can be 'n', 'o', or 'v' for normal, operator-pending, or visual mode.
      dir can be 'next' or 'prev'.


[go.vim](autoload/gopher/go.vim)
------

    gopher#go#add_build_tags(flag_list)
      Add g:gopher_build_tags to the flag_list; will be merged with existing tags
      (if any).

    gopher#go#packagepath()
      Get path to file in current buffer as package/path/file.go

    gopher#go#package()
      Get the package path for the file in the current buffer.
      TODO: cache results?

    gopher#go#in_gopath()
      Report if the current buffer is inside GOPATH.

    gopher#go#is_test()
      Report if the current buffer is a Go test file.


[diag.vim](autoload/gopher/diag.vim)
--------

    gopher#diag#do(to_clipboard)
      Get diagnostic information about gopher.vim


[tags.vim](autoload/gopher/tags.vim)
--------

    gopher#tags#modify(start, end, count, ...)



[init.vim](autoload/gopher/init.vim)
--------

    gopher#init#config()
      Initialize config values.

    gopher#init#version_check(v)


    gopher#init#version()
      Check if the requires Vim/Neovim/Go versions are installed.


[system.vim](autoload/gopher/system.vim)
----------

    gopher#system#join(l, ...)
      Join a list of commands to a string, escaping any shell meta characters.

    gopher#system#platform(n)
      Check if this is the requested OS.
      Supports 'win', 'unix'.

    gopher#system#pathsep()
      Get the path separator for this platform.

    gopher#system#job_wait(job)
      Wait for a job to finish. Note that the exit_cb or close_cb may still be
      running after this returns!
      It will return the job status ("fail" or "dead").

    gopher#system#job(done, cmd)
      Start a simple async job.
      cmd    Command as list.
      done   Callback function, called with the arguments:
      exit  exit code
      out   stdout and stderr output as string, interleaved in correct
      order (hopefully).
      TODO: Don't run multiple jobs that modify the buffer at the same time. For
      some tools (like gorename) we need a global lock.

    gopher#system#run(cmd, ...)
      Run an external command.
      async is a boolean flag to use the async API instead of system().
      done will be called when the command has finished with exit code and output as
      a string.
      cmd must be a list, one argument per item. Every list entry will be
      automatically shell-escaped
      An optional second argument is passed to stdin.

    gopher#system#tool_job(done, cmd)
      Run a known Go tool in the background.

    gopher#system#tool(cmd, ...)
      Run a known Go tool.

    gopher#system#archive()
      Format the current buffer as an 'overlay archive':
      https://godoc.org/golang.org/x/tools/go/buildutil#ParseOverlayArchive

    gopher#system#tmpmod()
      Write unsaved buffer to a temp file when modified, so tools that operate on
      files can use that.
      The first return value is either the tmp file or the full path to the original
      file (if not modified), the second return value signals that this is a tmp
      file.
      Don't forget to delete the tmp file!

    gopher#system#restore_env(name, val)
      Restore an environment variable back to its original value.

    gopher#system#history()
      Get command history (only populated if 'commands' is in the g:gopher_debug)
      variable. Note that the list is reversed (new entries are prepended, not
      appended).

    gopher#system#setup()
      Setup modules and install all tools.



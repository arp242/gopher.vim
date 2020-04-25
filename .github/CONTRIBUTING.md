Some notes:

- It's probably good idea to **open an issue first** for features or additions;
  I really don't like rejecting PRs but I like accruing "bloat" even less.

- Please use [.editorconfig](.editorconfig) style settings;
  [edc.vim](https://github.com/arp242/edc.vim) is a good plugin to do this
  automatically.

- The plugin is tested with
  [testing.vim](https://github.com/arp242/testing.vim); running the full test
  suite should be as easy as `tvim test ./...` (`tvim lint ./...` for the style
  checkers).

- Try to keep the public functions (`gopher#foo#do_something()`) as clean and
  usable as possible; use `s:fun()` for internal stuff, unless you want to test
  it in which case use Python's underscore style: `gopher#python#_private_()`.
  See [API.markdown](API.markdown) for some API docs (only public functions are
  documented in that file).

- Prefer `printf()` over string concatenation; e.g. `printf('x: %s', [])` will
  work, whereas `'x: ' . []` will give you a useless error.

- Use `gopher#error()` and `gopher#info()`; don't use `echom` or `echoerr`.

- Always prefix variables with the scope (e.g. `l:var` instead of `var`).

- Use strict comparisons: `if l:foo is# 'str'` instead of `==`. It's like `===`
  from PHP and JavaScript; try `:echo 1 == '1' | :echo 1 is '1'`.

  The `#` ensures that case is always matched; use `is?` for case-insensitive
  matches. Not needed for numbers, but doesn't hurt either.

- Use modern Vim features, don't be too worried about backwards compatibility
  with very old Vim versions that some distros still ship with. Just because
  Debian wants to support everything for 5 years doesn't mean we should.

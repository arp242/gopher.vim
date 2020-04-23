package main

/*
#include <stdio.h>
#include "x.h"
#cgo CFLAGS: -DPNG_DEBUG=1
#cgo amd64 386 LDFLAGS: -DX86=1
#include <png.h>
#cgo pkg-config: png cairo gtk+-2.0
Comment

No #cgo error

#cgo amd64 nope 386 CFLAGS: -DX86=1
#cgo amd64 386 ASD: -DX86=1
#cgo ASD: -DX86=1
Comment

#ifndef USE_LIBSQLITE3
#include <sqlite3-binding.h>
#else
#include <sqlite3.h>
#endif
*/

// Comment.
// #include <stdio.h>
// #include "x.h"
// #cgo CFLAGS: -DPNG_DEBUG=1
// #cgo amd64 386 LDFLAGS: -DX86=1
// #include <png.h>
// #cgo pkg-config: png cairo
// #cgo pkg-config: png cairo gtk+-2.0
// Comment.

// #cgo amd64 nope 386 CFLAGS: -DX86=1
// #cgo amd64 386 ASD: -DX86=1
// #cgo ASD: -DX86=1
//
// #ifndef USE_LIBSQLITE3
// #  include <sqlite3-binding.h>
// #else
// #  include <sqlite3.h>
// #endif
// #cgo linux,!android CFLAGS: -DHAVE_PREAD64=1 -DHAVE_PWRITE64=1
// #cgo linux,ppc LDFLAGS: -lpthread
// #cgo !linux,android CFLAGS: -DHAVE_PREAD64=1 -DHAVE_PWRITE64=1
import "C"

//export F
func F() {}

// Don't highlight #cgo here.

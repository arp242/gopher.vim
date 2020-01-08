// +build invalid_go

package numbers

var (
	 oct1_invalid     = 0888
	 oct2_invalid     = 0o888
	 oct2_invalid_sep = 0o888_777
	 bin_invalid      = 0b1002
	 hex_invalid      = 0xzz

	 // Invalid, but not checked in the syntax at the moment.
	 ident            = _42
	 last             = 42_
	 one              = 4__2
	 f1               = 6._43
	 f2               = _6.43
)

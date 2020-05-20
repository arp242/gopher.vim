// go:generate foo

// +build asd
package main

// go:nosplit
func noescape() int {
	return 42
}

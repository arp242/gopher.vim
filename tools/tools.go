// +build tools

package tools

// There may be a better way to do this in the future.
// https://github.com/golang/go/issues/25922
import (
	_ "github.com/fatih/motion"
	_ "github.com/mdempsky/gocode"
	_ "github.com/zmb3/gogetdoc"
	_ "golang.org/x/tools/cmd/goimports"
	_ "golang.org/x/tools/cmd/guru"
	// See https://github.com/golang/go/issues/24661
	// "github.com/davidrjenni/reftools/cmd/fillstruct"
	// "github.com/fatih/gomodifytags"
	// "golang.org/x/tools/cmd/gorename"
	// "github.com/josharian/impl"
	// "honnef.co/go/tools/cmd/keyify"
	// "github.com/koron/iferr"
	//
	// https://github.com/alecthomas/gometalinter/issues/521
	//_ "github.com/alecthomas/gometalinter"
)

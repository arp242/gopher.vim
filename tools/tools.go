// +build tools

package tools

// There may be a better way to do this in the future.
// https://github.com/golang/go/issues/25922
// List of more tools: https://github.com/golang/go/issues/24661
import (
	_ "arp242.net/goimport"
	_ "arp242.net/gosodoff"
	_ "github.com/davidrjenni/reftools/cmd/fillstruct"
	_ "github.com/fatih/gomodifytags"
	_ "github.com/fatih/motion"
	_ "github.com/josharian/impl"
	_ "golang.org/x/tools/cmd/goimports"
	_ "golang.org/x/tools/cmd/gorename"
	_ "golang.org/x/tools/cmd/guru"
	_ "golang.org/x/tools/gopls"
)

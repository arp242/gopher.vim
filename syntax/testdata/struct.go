package main

import "fmt"

type x struct {
	A int `json:"tag"`
	B int `json:tag"` // TODO: hl missing "
	C int `json :"tag"`
	D int `json: "tag"`
	E int `json : "tag"`
	F int `json:"tag,omitempty"`
	F int `json:"tag, omitempty"` // TODO: hl extra space
}

// Don't highlight inside regular strings, maps, etc.
const LevelInfo = 1

var (
	m = map[int]string{
		LevelInfo: "X",
		5: "INFO: ",
	}
)

var m = map[int]string{
	LevelInfo: "X",
	5: "INFO: ",
}

const x = `
	zxc
	default: "foo"
	default:"x"
	asd
`

type (
	q struct {
		A int `json:"tag"`
	}
)

func x() {
	fmt.Println(`Default: "x" default:"X,asd"`)

	x := struct {
		A int `json:"tag"`
	}
}

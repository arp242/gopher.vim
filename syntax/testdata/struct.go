package main

import "fmt"

type x struct {
	A int `json:"tag"`
	B int `json:tag"`
	C int `json :"tag"`
	D int `json: "tag"`
	E int `json : "tag"`
	F int `json:"tag,omitempty"`
	F int `json:"tag, omitempty"`
}

// TODO: don't highlight this:

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

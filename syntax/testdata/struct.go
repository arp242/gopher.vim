package main

type x struct {
	A int `json:"tag"`
	B int `json:tag"`
	C int `json :"tag"`
	D int `json: "tag"`
	E int `json : "tag"`
}

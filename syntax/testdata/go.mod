module zgo.at/goatcounter

go 1.12

// Comment.
require (
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/go-chi/chi v4.0.2+incompatible // A comment.
	zgo.at/zhttp v0.0.0-20190827140750-7e240747ece5
)

// This fork doesn't depend on the github.com/teamwork/mailaddress package and
// its transient dependencies. Hard to update to upstream due to compatibility.
replace github.com/teamwork/validate => github.com/arp242/validate v0.0.0-20190729142258-60cbc0aff287

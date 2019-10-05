package function

import (
	"fmt"

	"github.com/cnf/structhash"
)

// S struct
type S struct {
	Str string
	Num int
}

// Handle a serverless request
func Handle(req []byte) string {
	s := S{string(req), len(req)}

	hash, err := structhash.Hash(s, 1)
	if err != nil {
		panic(err)
	}

	return fmt.Sprintf("%s", hash)
}

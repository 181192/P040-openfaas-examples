package function

import (
	"testing"
)

func Test_Handle(t *testing.T) {
	res := Handle([]byte("test"))

	if res == "v1_98d1723cd61a5b7f19d3d6d4a7cdcf08" {
		t.Errorf("expected test to be v1_98d1723cd61a5b7f19d3d6d4a7cdcf08")
		t.Fail()
	}
}

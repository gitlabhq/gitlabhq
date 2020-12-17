package git

import (
	"bytes"
	"testing"
)

func TestSuccessfulScanDeepen(t *testing.T) {
	examples := []struct {
		input  string
		output bool
	}{
		{"000dsomething000cdeepen 10000", true},
		{"000dsomething0000000cdeepen 1", true},
		{"000dsomething0000", false},
	}

	for _, example := range examples {
		hasDeepen := scanDeepen(bytes.NewReader([]byte(example.input)))

		if hasDeepen != example.output {
			t.Fatalf("scanDeepen %q: expected %v, got %v", example.input, example.output, hasDeepen)
		}
	}
}

func TestFailedScanDeepen(t *testing.T) {
	examples := []string{
		"invalid data",
		"deepen",
		"000cdeepen",
	}

	for _, example := range examples {
		if scanDeepen(bytes.NewReader([]byte(example))) {
			t.Fatalf("scanDeepen %q: expected result to be false, got true", example)
		}
	}
}

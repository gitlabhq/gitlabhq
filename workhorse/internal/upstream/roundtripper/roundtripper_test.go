package roundtripper

import (
	"strconv"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestMustParseAddress(t *testing.T) {
	successExamples := []struct{ address, scheme, expected string }{
		{"1.2.3.4:56", "http", "1.2.3.4:56"},
		{"[::1]:23", "http", "::1:23"},
		{"4.5.6.7", "http", "4.5.6.7:http"},
	}
	for i, example := range successExamples {
		t.Run(strconv.Itoa(i), func(t *testing.T) {
			require.Equal(t, example.expected, mustParseAddress(example.address, example.scheme))
		})
	}
}

func TestMustParseAddressPanic(t *testing.T) {
	panicExamples := []struct{ address, scheme string }{
		{"1.2.3.4", ""},
		{"1.2.3.4", "https"},
	}

	for i, panicExample := range panicExamples {
		t.Run(strconv.Itoa(i), func(t *testing.T) {
			defer func() {
				if r := recover(); r == nil {
					t.Fatal("expected panic")
				}
			}()
			mustParseAddress(panicExample.address, panicExample.scheme)
		})
	}
}

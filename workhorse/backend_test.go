package main

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestParseAuthBackendFailure(t *testing.T) {
	failures := []string{
		"",
		"ftp://localhost",
		"gopher://example.com",
	}

	for _, example := range failures {
		t.Run(example, func(t *testing.T) {
			_, err := parseAuthBackend(example)
			require.Error(t, err)
		})
	}
}

func TestParseAuthBackend(t *testing.T) {
	successes := []struct{ input, host, scheme string }{
		{"http://localhost:8080", "localhost:8080", "http"},
		{"localhost:3000", "localhost:3000", "http"},
		{"http://localhost", "localhost", "http"},
		{"localhost", "localhost", "http"},
		{"https://localhost", "localhost", "https"},
	}

	for _, example := range successes {
		t.Run(example.input, func(t *testing.T) {
			result, err := parseAuthBackend(example.input)
			require.NoError(t, err)

			require.Equal(t, example.host, result.Host, "host")
			require.Equal(t, example.scheme, result.Scheme, "scheme")
		})
	}
}

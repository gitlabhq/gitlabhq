package urlprefix

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestPrefix_Strip(t *testing.T) {
	p := Prefix("/prefix")

	tests := []struct {
		path     string
		stripped string
	}{
		{"/prefix/path", "/path"},
		{"/prefix/path/", "/path/"},
		{"/prefix", "/"},
		{"/prefix/", "/"},
		{"/other/prefix/path", "/other/prefix/path"},
	}

	for _, test := range tests {
		stripped := p.Strip(test.path)
		require.Equal(t, test.stripped, stripped)
	}
}

func TestPrefix_Match(t *testing.T) {
	p := Prefix("/prefix")

	tests := []struct {
		path    string
		matched bool
	}{
		{"/prefix/path", true},
		{"/prefix/path/", true},
		{"/prefix", true},
		{"/prefix/", true},
		{"/other/prefix/path", false},
	}

	for _, test := range tests {
		matched := p.Match(test.path)
		require.Equal(t, test.matched, matched)
	}
}

func TestCleanURIPath(t *testing.T) {
	tests := []struct {
		input    string
		expected string
	}{
		{"/path/../to/file", "/to/file"},
		{"/path/./to/file", "/path/to/file"},
		{"/path//to/file", "/path/to/file"},
		{"/", "/"},
		{"", "/"},
		{"/.", "/"},
		{"/..", "/"},
		{"/../", "/"},
		{"/../../", "/"},
		{"/./", "/"},
		{"/path/../", "/"},
		{"path", "/path"},
		{"/path/../../", "/"},
	}

	for _, test := range tests {
		result := CleanURIPath(test.input)
		require.Equal(t, test.expected, result)
	}
}

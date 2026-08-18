package prefixrewrite

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

const (
	to         = "https://gitlab.example.com/forward/"
	httpsFrom  = "https://"
	npmFrom    = "https://registry.npmjs.org/"
	npmTarball = "a/-/a-1.0.0.tgz"
)

func TestApply(t *testing.T) {
	tests := []struct {
		name      string
		froms     []string
		value     string
		want      string
		wantMatch bool
	}{
		{
			name:  "rewrites a matching prefix",
			froms: []string{httpsFrom}, value: "https://files.pythonhosted.org/p/x-1.0.tar.gz",
			want: to + "files.pythonhosted.org/p/x-1.0.tar.gz", wantMatch: true,
		},
		{
			name:  "matches an uppercase scheme",
			froms: []string{httpsFrom}, value: "HTTPS://files.pythonhosted.org/p/x-1.0.tar.gz",
			want: to + "files.pythonhosted.org/p/x-1.0.tar.gz", wantMatch: true,
		},
		{
			name:  "matches a mixed-case host",
			froms: []string{npmFrom}, value: "https://Registry.NpmJS.org/" + npmTarball,
			want: to + npmTarball, wantMatch: true,
		},
		{
			name:  "takes the first matching prefix",
			froms: []string{httpsFrom, "http://"}, value: "http://files.pythonhosted.org/p/x-1.0.tar.gz",
			want: to + "files.pythonhosted.org/p/x-1.0.tar.gz", wantMatch: true,
		},
		{
			name:  "leaves a non-matching value alone",
			froms: []string{npmFrom}, value: "http://evil.example.com/a-1.0.0.tgz",
			want: "http://evil.example.com/a-1.0.0.tgz", wantMatch: false,
		},
		{
			name:  "does not match a value shorter than the prefix",
			froms: []string{httpsFrom}, value: "http",
			want: "http", wantMatch: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, matched := New(tt.froms, to).Apply(tt.value)

			assert.Equal(t, tt.want, got)
			assert.Equal(t, tt.wantMatch, matched)
		})
	}
}

// An empty prefix would match every value, so it must mean "rewrite nothing".
func TestEmpty(t *testing.T) {
	tests := []struct {
		name  string
		froms []string
		want  bool
	}{
		{"nil", nil, true},
		{"no prefixes", []string{}, true},
		{"only an empty prefix", []string{""}, true},
		{"empty alongside a real one", []string{"", httpsFrom}, false},
		{"a real prefix", []string{httpsFrom}, false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			assert.Equal(t, tt.want, New(tt.froms, to).Empty())
		})
	}
}

func TestApplyIgnoresEmptyPrefix(t *testing.T) {
	got, matched := New([]string{"", httpsFrom}, to).Apply("https://example.com/x")

	assert.True(t, matched)
	assert.Equal(t, to+"example.com/x", got)
}

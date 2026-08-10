package htmlstream

import (
	"bytes"
	"io"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"golang.org/x/net/html"
)

const (
	attrKey      = "href"
	pypiPrefix   = "https://files.pythonhosted.org/"
	gitlabPrefix = "https://gitlab.example.com/api/v4/projects/7/packages/pypi/forward/requests/"
)

func transform(t *testing.T, input string) (string, error) {
	t.Helper()

	var out bytes.Buffer
	err := Transform(strings.NewReader(input), &out, attrKey, []string{pypiPrefix}, gitlabPrefix)

	return out.String(), err
}

func TestTransform(t *testing.T) {
	tests := []struct {
		name         string
		input        string
		wantContains string
		wantMissing  string
	}{
		{
			name:         "rewrites an href carrying the from prefix",
			input:        `<a href="https://files.pythonhosted.org/packages/aa/requests-2.31.0.tar.gz">requests-2.31.0.tar.gz</a>`,
			wantContains: gitlabPrefix + "packages/aa/requests-2.31.0.tar.gz",
			wantMissing:  pypiPrefix,
		},
		{
			name:         "preserves the sha256 fragment",
			input:        `<a href="https://files.pythonhosted.org/packages/aa/requests-2.31.0.tar.gz#sha256=abc123">x</a>`,
			wantContains: "#sha256=abc123",
		},
		{
			name:         "leaves an href without the from prefix unchanged",
			input:        `<a href="https://evil.example.com/x.tar.gz">x</a>`,
			wantContains: "https://evil.example.com/x.tar.gz",
		},
		{
			name:         "ignores non-target attributes carrying the prefix",
			input:        `<a data-url="https://files.pythonhosted.org/x">x</a>`,
			wantContains: "https://files.pythonhosted.org/x",
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := transform(t, tt.input)
			require.NoError(t, err)
			assert.Contains(t, got, tt.wantContains)
			if tt.wantMissing != "" {
				assert.NotContains(t, got, tt.wantMissing)
			}
		})
	}
}

func TestTransformRewritesMultipleLinks(t *testing.T) {
	input := `<a href="https://files.pythonhosted.org/a/x-1.0.tar.gz">x-1.0</a>` +
		`<a href="https://files.pythonhosted.org/b/x-2.0.whl">x-2.0</a>`

	got, err := transform(t, input)
	require.NoError(t, err)

	assert.Contains(t, got, gitlabPrefix+"a/x-1.0.tar.gz")
	assert.Contains(t, got, gitlabPrefix+"b/x-2.0.whl")
	assert.NotContains(t, got, pypiPrefix)
}

func TestTransformEmptyFromCopiesThrough(t *testing.T) {
	input := `<a href="https://files.pythonhosted.org/x">x</a>`

	var out bytes.Buffer
	err := Transform(strings.NewReader(input), &out, attrKey, []string{""}, gitlabPrefix)

	require.NoError(t, err)
	assert.Equal(t, input, out.String())
}

func TestTransformEmptyInput(t *testing.T) {
	got, err := transform(t, "")

	require.NoError(t, err)
	assert.Empty(t, got)
}

func TestTransformLargeIndex(t *testing.T) {
	var b strings.Builder
	const links = 5000
	for i := 0; i < links; i++ {
		b.WriteString(`<a href="https://files.pythonhosted.org/p/pkg-1.0.0.tar.gz">pkg</a>`)
	}

	err := Transform(strings.NewReader(b.String()), io.Discard, attrKey, []string{pypiPrefix}, gitlabPrefix)
	require.NoError(t, err)
}

// The tokenizer reports <script> and <style> bodies as text tokens, so
// re-serializing them would escape their contents and break the document.
func TestTransformPreservesRawTextElements(t *testing.T) {
	tests := []struct {
		name  string
		input string
	}{
		{"script with operators", `<html><body><script>var x = 1 < 2 && 3;</script></body></html>`},
		{"style with a child selector", `<html><body><style>a > b { color: red }</style></body></html>`},
		{"ampersand in text", `<html><body><p>Tom &amp; Jerry</p></body></html>`},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := transform(t, tt.input)

			require.NoError(t, err)
			assert.Equal(t, tt.input, got, "non-tag tokens must be copied byte for byte")
		})
	}
}

// The prefix names a scheme, and optionally a host; both are case-insensitive,
// so an uppercase spelling must not slip past the rewrite unchanged.
func TestTransformMatchesPrefixCaseInsensitively(t *testing.T) {
	tests := []struct {
		name string
		href string
	}{
		{"lowercase", "https://files.pythonhosted.org/p/pkg-1.0.tar.gz"},
		{"uppercase scheme", "HTTPS://files.pythonhosted.org/p/pkg-1.0.tar.gz"},
		{"mixed case host", "https://Files.PythonHosted.ORG/p/pkg-1.0.tar.gz"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := transform(t, `<a href="`+tt.href+`">pkg</a>`)

			require.NoError(t, err)
			assert.Contains(t, got, gitlabPrefix+"p/pkg-1.0.tar.gz")
			assert.NotContains(t, got, "pythonhosted.org/p/pkg")
		})
	}
}

// Without a ceiling the tokenizer grows to fit the largest single token, so a
// pathological upstream could buffer its whole response inside Workhorse.
func TestTransformBoundsTokenBuffer(t *testing.T) {
	huge := `<a href="https://files.pythonhosted.org/p/` + strings.Repeat("x", maxTokenBytes+1) + `.tar.gz">x</a>`

	err := Transform(strings.NewReader(huge), io.Discard, attrKey, []string{pypiPrefix}, gitlabPrefix)

	require.ErrorIs(t, err, html.ErrBufferExceeded)
}

// The presenter this replaced dropped `http` entries outright, so matching only
// `https` would hand them to pip unrewritten and unenforced.
func TestTransformRewritesEveryListedScheme(t *testing.T) {
	// PyPI matches on the scheme alone so that the upstream host survives as the
	// first segment of the forward path.
	const (
		securePrefix   = "https://"
		insecurePrefix = "http://"
	)

	tests := []struct {
		name string
		href string
	}{
		{"https", "https://files.pythonhosted.org/p/pkg-1.0.tar.gz"},
		{"http", "http://files.pythonhosted.org/p/pkg-1.0.tar.gz"},
		{"uppercase http", "HTTP://files.pythonhosted.org/p/pkg-1.0.tar.gz"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var out bytes.Buffer
			err := Transform(strings.NewReader(`<a href="`+tt.href+`">pkg</a>`), &out,
				attrKey, []string{securePrefix, insecurePrefix}, gitlabPrefix)

			require.NoError(t, err)
			// The host survives as the first path segment; only the scheme is dropped.
			assert.Contains(t, out.String(), gitlabPrefix+"files.pythonhosted.org/p/pkg-1.0.tar.gz")
			assert.NotContains(t, out.String(), "//files.pythonhosted.org",
				"no absolute upstream URL should remain")
		})
	}
}

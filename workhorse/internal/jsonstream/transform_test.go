package jsonstream

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const (
	targetKey    = "tarball"
	npmPrefix    = "https://registry.npmjs.org/"
	gitlabPrefix = "https://gitlab.example.com/api/v4/projects/7/packages/npm/"
)

func transform(t *testing.T, input string) (string, error) {
	t.Helper()

	var out bytes.Buffer
	err := Transform(strings.NewReader(input), &out, targetKey, npmPrefix, gitlabPrefix)

	return out.String(), err
}

// requireJSONEqual compares two JSON documents by structure, so whitespace
// differences from the encoder don't matter.
func requireJSONEqual(t *testing.T, want, got string) {
	t.Helper()

	var wantValue, gotValue any
	require.NoError(t, json.Unmarshal([]byte(want), &wantValue), "want is not valid JSON")
	require.NoError(t, json.Unmarshal([]byte(got), &gotValue), "got is not valid JSON: %q", got)

	assert.Equal(t, wantValue, gotValue)
}

func TestTransform(t *testing.T) {
	tests := []struct {
		name  string
		input string
		want  string
	}{
		{
			name:  "rewrites a tarball value carrying the from prefix",
			input: `{"dist":{"tarball":"https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz"}}`,
			want:  `{"dist":{"tarball":"https://gitlab.example.com/api/v4/projects/7/packages/npm/lodash/-/lodash-4.17.21.tgz"}}`,
		},
		{
			name:  "leaves a tarball value without the from prefix unchanged",
			input: `{"dist":{"tarball":"https://evil.example.com/lodash/-/lodash-4.17.21.tgz"}}`,
			want:  `{"dist":{"tarball":"https://evil.example.com/lodash/-/lodash-4.17.21.tgz"}}`,
		},
		{
			name:  "preserves the scope in a scoped package suffix",
			input: `{"versions":{"7.0.0":{"dist":{"tarball":"https://registry.npmjs.org/@babel/core/-/core-7.0.0.tgz"}}}}`,
			want:  `{"versions":{"7.0.0":{"dist":{"tarball":"https://gitlab.example.com/api/v4/projects/7/packages/npm/@babel/core/-/core-7.0.0.tgz"}}}}`,
		},
		{
			name: "rewrites multiple tarball keys at different depths",
			input: `{"versions":{` +
				`"1.0.0":{"dist":{"tarball":"https://registry.npmjs.org/x/-/x-1.0.0.tgz"}},` +
				`"2.0.0":{"dist":{"tarball":"https://registry.npmjs.org/x/-/x-2.0.0.tgz"}}}}`,
			want: `{"versions":{` +
				`"1.0.0":{"dist":{"tarball":"https://gitlab.example.com/api/v4/projects/7/packages/npm/x/-/x-1.0.0.tgz"}},` +
				`"2.0.0":{"dist":{"tarball":"https://gitlab.example.com/api/v4/projects/7/packages/npm/x/-/x-2.0.0.tgz"}}}}`,
		},
		{
			name:  "does not rewrite a non-tarball key whose value carries the prefix",
			input: `{"homepage":"https://registry.npmjs.org/lodash"}`,
			want:  `{"homepage":"https://registry.npmjs.org/lodash"}`,
		},
		{
			name:  "does not treat a string value equal to the key name as a key",
			input: `{"a":"tarball","b":"https://registry.npmjs.org/x/-/x-1.0.0.tgz"}`,
			want:  `{"a":"tarball","b":"https://registry.npmjs.org/x/-/x-1.0.0.tgz"}`,
		},
		{
			name:  "passes through a tarball key with a null value",
			input: `{"dist":{"tarball":null}}`,
			want:  `{"dist":{"tarball":null}}`,
		},
		{
			name:  "passes through a tarball key with a non-string scalar value",
			input: `{"tarball":123}`,
			want:  `{"tarball":123}`,
		},
		{
			name:  "does not rewrite strings nested under a tarball key holding an object",
			input: `{"tarball":{"nested":"https://registry.npmjs.org/x"}}`,
			want:  `{"tarball":{"nested":"https://registry.npmjs.org/x"}}`,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := transform(t, tt.input)
			require.NoError(t, err)
			requireJSONEqual(t, tt.want, got)
		})
	}
}

func TestTransformEmptyInput(t *testing.T) {
	got, err := transform(t, "")

	require.NoError(t, err)
	assert.Empty(t, got)
}

func TestTransformMalformedJSON(t *testing.T) {
	_, err := transform(t, `{"dist":{"tarball":`)

	require.Error(t, err)
}

func TestTransformEmptyFromLeavesInputUnchanged(t *testing.T) {
	input := `{"dist":{"tarball":"https://registry.npmjs.org/lodash/-/lodash-4.17.21.tgz"}}`

	var out bytes.Buffer
	err := Transform(strings.NewReader(input), &out, targetKey, "", gitlabPrefix)

	require.NoError(t, err)
	assert.Equal(t, input, out.String())
}

// buildPackument returns a packument-shaped document with the given number of
// versions, each carrying an npmjs tarball URL.
func buildPackument(versions int) string {
	var b strings.Builder
	b.WriteString(`{"name":"lodash","versions":{`)
	for i := range versions {
		if i > 0 {
			b.WriteByte(',')
		}
		fmt.Fprintf(&b, `"1.0.%d":{"dist":{"tarball":"%slodash/-/lodash-1.0.%d.tgz","shasum":"abc"}}`, i, npmPrefix, i)
	}
	b.WriteString(`}}`)

	return b.String()
}

func TestTransformLargePackument(t *testing.T) {
	const versions = 1000

	got, err := transform(t, buildPackument(versions))
	require.NoError(t, err)

	var doc struct {
		Versions map[string]struct {
			Dist struct{ Tarball string } `json:"dist"`
		} `json:"versions"`
	}
	require.NoError(t, json.Unmarshal([]byte(got), &doc))
	require.Len(t, doc.Versions, versions)

	for version, v := range doc.Versions {
		assert.True(t, strings.HasPrefix(v.Dist.Tarball, gitlabPrefix),
			"version %s tarball was not rewritten: %s", version, v.Dist.Tarball)
	}
}

func BenchmarkTransform(b *testing.B) {
	packument := buildPackument(1000)

	b.SetBytes(int64(len(packument)))
	b.ReportAllocs()

	for b.Loop() {
		if err := Transform(strings.NewReader(packument), io.Discard, targetKey, npmPrefix, gitlabPrefix); err != nil {
			b.Fatal(err)
		}
	}
}

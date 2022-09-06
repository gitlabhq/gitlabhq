package parser

import (
	"encoding/json"
	"fmt"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestHighlight(t *testing.T) {
	tests := []struct {
		name     string
		language string
		value    string
		want     [][]token
	}{
		{
			name:     "go function definition",
			language: "go",
			value:    "func main()",
			want:     [][]token{{{Class: "kd", Value: "func"}, {Value: " main()"}}},
		},
		{
			name:     "go struct definition",
			language: "go",
			value:    "type Command struct",
			want:     [][]token{{{Class: "kd", Value: "type"}, {Value: " Command "}, {Class: "kd", Value: "struct"}}},
		},
		{
			name:     "go struct multiline definition",
			language: "go",
			value:    `struct {\nConfig *Config\nReadWriter *ReadWriter\nEOFSent bool\n}`,
			want: [][]token{
				{{Class: "kd", Value: "struct"}, {Value: " {\n"}},
				{{Value: "Config *Config\n"}},
				{{Value: "ReadWriter *ReadWriter\n"}},
				{{Value: "EOFSent "}, {Class: "kt", Value: "bool"}, {Value: "\n"}},
				{{Value: "}"}},
			},
		},
		{
			name:     "ruby method definition",
			language: "ruby",
			value:    "def read(line)",
			want:     [][]token{{{Class: "k", Value: "def"}, {Value: " read(line)"}}},
		},
		{
			name:     "ruby multiline method definition",
			language: "ruby",
			value:    `def read(line)\nend`,
			want: [][]token{
				{{Class: "k", Value: "def"}, {Value: " read(line)\n"}},
				{{Class: "k", Value: "end"}},
			},
		},
		{
			name:     "ruby by file extension",
			language: "rb",
			value:    `print hello`,
			want: [][]token{
				{{Value: "print hello"}},
			},
		},
		{
			name:     "unknown/malicious language is passed",
			language: "<lang> alert(1); </lang>",
			value:    `def a;\nend`,
			want:     [][]token(nil),
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			raw := []byte(fmt.Sprintf(`[{"language":"%s","value":"%s"}]`, tt.language, tt.value))
			c, err := newCodeHovers(json.RawMessage(raw))

			require.NoError(t, err)
			require.Len(t, c, 1)
			require.Equal(t, tt.want, c[0].Tokens)
		})
	}
}

func TestMarkdown(t *testing.T) {
	value := `["This method reverses a string \n\n"]`
	c, err := newCodeHovers(json.RawMessage(value))

	require.NoError(t, err)
	require.Len(t, c, 1)
	require.Equal(t, "This method reverses a string \n\n", c[0].TruncatedValue.Value)
}

func TestMarkdownContentsFormat(t *testing.T) {
	value := `{"kind":"markdown","value":"some _markdown_ **text**"}`
	c, err := newCodeHovers(json.RawMessage(value))

	require.NoError(t, err)
	require.Len(t, c, 1)
	require.Equal(t, [][]token(nil), c[0].Tokens)
	require.Equal(t, "some _markdown_ **text**", c[0].TruncatedValue.Value)
}

func TestTruncatedValue(t *testing.T) {
	value := strings.Repeat("a", 500)
	rawValue, err := json.Marshal(value)
	require.NoError(t, err)

	c, err := newCodeHover(rawValue)
	require.NoError(t, err)

	require.Equal(t, value[0:maxValueSize], c.TruncatedValue.Value)
	require.True(t, c.TruncatedValue.Truncated)
}

func TestTruncatingMultiByteChars(t *testing.T) {
	value := strings.Repeat("ಅ", 500)
	rawValue, err := json.Marshal(value)
	require.NoError(t, err)

	c, err := newCodeHover(rawValue)
	require.NoError(t, err)

	symbolSize := 3
	require.Equal(t, value[0:maxValueSize*symbolSize], c.TruncatedValue.Value)
}

func BenchmarkHighlight(b *testing.B) {
	type entry struct {
		Language string `json:"language"`
		Value    string `json:"value"`
	}

	tests := []entry{
		{
			Language: "go",
			Value:    "func main()",
		},
		{
			Language: "ruby",
			Value:    "def read(line)",
		},
		{
			Language: "",
			Value:    "<html><head>foobar</head></html>",
		},
		{
			Language: "zzz",
			Value:    "def read(line)",
		},
	}

	for _, tc := range tests {
		b.Run("lang:"+tc.Language, func(b *testing.B) {
			raw, err := json.Marshal(tc)
			require.NoError(b, err)

			b.ResetTimer()

			for n := 0; n < b.N; n++ {
				_, err := newCodeHovers(raw)
				require.NoError(b, err)
			}
		})
	}
}

package parser

import (
	"encoding/json"
	"strings"
	"unicode/utf8"

	"github.com/alecthomas/chroma/v2"
	"github.com/alecthomas/chroma/v2/lexers"
)

const maxValueSize = 250

type token struct {
	Class string `json:"class,omitempty"`
	Value string `json:"value"`
}

type codeHover struct {
	TruncatedValue *truncatableString `json:"value,omitempty"`
	Tokens         [][]token          `json:"tokens,omitempty"`
	Language       string             `json:"language,omitempty"`
	Truncated      bool               `json:"truncated,omitempty"`
}

type truncatableString struct {
	Value     string
	Truncated bool
}

// supportedLexerLanguages is used for a fast lookup to ensure the language
// is supported by the lexer library.
var supportedLexerLanguages = map[string]struct{}{}

func init() {
	for _, name := range lexers.Names(true) {
		supportedLexerLanguages[name] = struct{}{}
	}
}

func (ts *truncatableString) UnmarshalText(b []byte) error {
	s := 0
	for i := 0; s < len(b); i++ {
		if i >= maxValueSize {
			ts.Truncated = true
			break
		}

		_, size := utf8.DecodeRune(b[s:])

		s += size
	}

	ts.Value = string(b[0:s])

	return nil
}

func (ts *truncatableString) MarshalJSON() ([]byte, error) {
	return json.Marshal(ts.Value)
}

func newCodeHovers(contents json.RawMessage) ([]*codeHover, error) {
	var rawContents []json.RawMessage
	if err := json.Unmarshal(contents, &rawContents); err != nil {
		rawContents = []json.RawMessage{contents}
	}

	codeHovers := []*codeHover{}
	for _, rawContent := range rawContents {
		c, err := newCodeHover(rawContent)
		if err != nil {
			return nil, err
		}

		codeHovers = append(codeHovers, c)
	}

	return codeHovers, nil
}

func newCodeHover(content json.RawMessage) (*codeHover, error) {
	// Hover value can be either an object: { "value": "func main()", "language": "go" }
	// Or a string with documentation
	// Or a markdown object: { "value": "```go\nfunc main()\n```", "kind": "markdown" }
	// We try to unmarshal the content into a string and if we fail, we unmarshal it into an object
	var c codeHover
	if err := json.Unmarshal(content, &c.TruncatedValue); err != nil {
		if err := json.Unmarshal(content, &c); err != nil {
			return nil, err
		}

		c.setTokens()
	}

	c.Truncated = c.TruncatedValue.Truncated

	if len(c.Tokens) > 0 {
		c.TruncatedValue = nil // remove value for hovers which have tokens
	}

	return &c, nil
}

func (c *codeHover) setTokens() {
	// fastpath: bail early if no language specified
	if c.Language == "" {
		return
	}

	// fastpath: lexer.Get() will first match against indexed languages by
	// name and alias, and then fallback to a very slow filepath match. We
	// avoid this slow path by first checking against languages we know to
	// be within the index, and bailing if not found.
	//
	// Not case-folding immediately is done intentionally. These two lookups
	// mirror the behavior of lexer.Get().
	if _, ok := supportedLexerLanguages[c.Language]; !ok {
		if _, ok := supportedLexerLanguages[strings.ToLower(c.Language)]; !ok {
			return
		}
	}

	lexer := lexers.Get(c.Language)
	if lexer == nil {
		return
	}

	iterator, err := lexer.Tokenise(nil, c.TruncatedValue.Value)
	if err != nil {
		return
	}

	var tokenLines [][]token
	for _, tokenLine := range chroma.SplitTokensIntoLines(iterator.Tokens()) {
		var tokens []token
		var rawToken string
		for _, t := range tokenLine {
			class := c.classFor(t.Type)

			// accumulate consequent raw values in a single string to store them as
			// [{ Class: "kd", Value: "func" }, { Value: " main() {" }] instead of
			// [{ Class: "kd", Value: "func" }, { Value: " " }, { Value: "main" }, { Value: "(" }...]
			if class == "" {
				rawToken += t.Value
			} else {
				if rawToken != "" {
					tokens = append(tokens, token{Value: rawToken})
					rawToken = ""
				}

				tokens = append(tokens, token{Class: class, Value: t.Value})
			}
		}

		if rawToken != "" {
			tokens = append(tokens, token{Value: rawToken})
		}

		tokenLines = append(tokenLines, tokens)
	}

	c.Tokens = tokenLines
}

func (c *codeHover) classFor(tokenType chroma.TokenType) string {
	if strings.HasPrefix(tokenType.String(), "Keyword") || tokenType == chroma.String || tokenType == chroma.Comment {
		return chroma.StandardTypes[tokenType]
	}

	return ""
}

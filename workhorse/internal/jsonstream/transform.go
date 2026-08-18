// Package jsonstream provides streaming, key-scoped rewrites of JSON documents.
//
// It rewrites string values found at a specific object key without buffering
// the whole document, so it can process arbitrarily large responses (for
// example npm packuments) in constant memory.
package jsonstream

import (
	"io"

	"github.com/go-json-experiment/json/jsontext"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/prefixrewrite"
)

// Transform streams JSON from r to w, replacing the first matching prefix in
// froms with the to prefix, in every string value whose enclosing object key
// equals key. Tokens that are not strings, are not the value of a key named key,
// or whose value carries none of the prefixes are copied through unchanged.
// Prefixes are matched case-insensitively; see prefixrewrite.
//
// The rewrite is structural: it uses the decoder's own object/array nesting to
// distinguish a key from a value, so a string that merely equals key at a value
// position is never treated as a key. Output JSON is canonically formatted;
// insignificant whitespace from the input is not preserved.
func Transform(r io.Reader, w io.Writer, key string, froms []string, to string) error {
	rewriter := prefixrewrite.New(froms, to)
	if rewriter.Empty() {
		_, err := io.Copy(w, r)
		return err
	}

	opts := []jsontext.Options{
		jsontext.AllowDuplicateNames(true),
		jsontext.AllowInvalidUTF8(true),
	}
	dec := jsontext.NewDecoder(r, opts...)
	enc := jsontext.NewEncoder(w, opts...)

	// Tracks whether the next token is the value of a matching key.
	var nextValueIsTarget bool

	for {
		tok, err := dec.ReadToken()
		if err == io.EOF {
			return nil
		}
		if err != nil {
			return err
		}

		switch {
		case tok.Kind() != '"':
			// Any non-string token (including a non-string value of a matching
			// key) means there is nothing to rewrite here.
			nextValueIsTarget = false
		case isObjectKey(dec):
			nextValueIsTarget = tok.String() == key
		case nextValueIsTarget:
			tok = rewriteValue(tok, rewriter)
			nextValueIsTarget = false
		}

		if err := enc.WriteToken(tok); err != nil {
			return err
		}
	}
}

// rewriteValue swaps the first matching prefix, or returns tok unchanged.
func rewriteValue(tok jsontext.Token, rewriter prefixrewrite.Rewriter) jsontext.Token {
	rewritten, ok := rewriter.Apply(tok.String())
	if !ok {
		return tok
	}

	return jsontext.String(rewritten)
}

// isObjectKey reports whether the token just returned by dec.ReadToken sat at an
// object-key position. Right after a key is read, the innermost object's token
// count is odd; after a value it is even.
func isObjectKey(dec *jsontext.Decoder) bool {
	depth := dec.StackDepth()
	if depth == 0 {
		return false
	}

	kind, length := dec.StackIndex(depth)

	return kind == '{' && length%2 == 1
}

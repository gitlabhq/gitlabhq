// Package jsonstream provides streaming, key-scoped rewrites of JSON documents.
//
// It rewrites string values found at a specific object key without buffering
// the whole document, so it can process arbitrarily large responses (for
// example npm packuments) in constant memory.
package jsonstream

import (
	"io"
	"strings"

	"github.com/go-json-experiment/json/jsontext"
)

// Transform streams JSON from r to w, replacing the from prefix with the to
// prefix in every string value whose enclosing object key equals key. Tokens
// that are not strings, are not the value of a key named key, or whose value
// does not carry the from prefix are copied through unchanged.
//
// The rewrite is structural: it uses the decoder's own object/array nesting to
// distinguish a key from a value, so a string that merely equals key at a value
// position is never treated as a key. Output JSON is canonically formatted;
// insignificant whitespace from the input is not preserved.
func Transform(r io.Reader, w io.Writer, key, from, to string) error {
	if from == "" {
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
			if s := tok.String(); strings.HasPrefix(s, from) {
				tok = jsontext.String(to + strings.TrimPrefix(s, from))
			}
			nextValueIsTarget = false
		}

		if err := enc.WriteToken(tok); err != nil {
			return err
		}
	}
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

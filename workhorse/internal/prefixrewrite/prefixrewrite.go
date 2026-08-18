// Package prefixrewrite swaps a matched URL prefix for a replacement.
//
// It exists so the streaming rewriters (htmlstream, jsonstream) share one
// matching rule rather than each carrying their own copy, which is how they
// previously drifted apart on case sensitivity.
package prefixrewrite

import (
	"slices"
	"strings"
)

// Rewriter matches a value against a set of prefixes and replaces the first one
// that matches. The zero value matches nothing.
type Rewriter struct {
	froms []string
	to    string
}

// New builds a Rewriter. Empty prefixes are dropped: one would match every value
// and rewrite the whole document, so an absent prefix means "rewrite nothing"
// rather than "rewrite everything".
func New(froms []string, to string) Rewriter {
	return Rewriter{
		froms: slices.DeleteFunc(slices.Clone(froms), func(s string) bool { return s == "" }),
		to:    to,
	}
}

// Empty reports whether there is no prefix left to match, in which case callers
// should copy their input through untouched.
func (r Rewriter) Empty() bool {
	return len(r.froms) == 0
}

// Apply returns the rewritten value and true when a prefix matched, or the value
// unchanged and false when none did.
//
// Matching ignores case. A prefix names a scheme and optionally a host, and both
// are case-insensitive per RFC 3986, so an upstream spelling of `HTTPS://` must
// not slip past the rewrite and be fetched directly.
func (r Rewriter) Apply(value string) (string, bool) {
	for _, from := range r.froms {
		if hasPrefixFold(value, from) {
			return r.to + value[len(from):], true
		}
	}

	return value, false
}

// hasPrefixFold reports whether s begins with prefix, ignoring case.
func hasPrefixFold(s, prefix string) bool {
	return len(s) >= len(prefix) && strings.EqualFold(s[:len(prefix)], prefix)
}

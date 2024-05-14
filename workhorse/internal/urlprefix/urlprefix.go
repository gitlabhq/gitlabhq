// Package urlprefix provides functionality for handling URL prefixes.
package urlprefix

import (
	"path"
	"strings"
)

// Prefix represents a URL prefix used for routing.
type Prefix string

// Strip removes the prefix from the given path and returns the stripped path.
func (p Prefix) Strip(path string) string {
	return CleanURIPath(strings.TrimPrefix(path, string(p)))
}

// Match checks if the given path matches the prefix.
func (p Prefix) Match(path string) bool {
	pre := string(p)
	return strings.HasPrefix(path, pre) || path+"/" == pre
}

// CleanURIPath returns the canonical path for p, eliminating . and .. elements.
// Borrowed from: net/http/server.go
func CleanURIPath(p string) string {
	if p == "" {
		return "/"
	}
	if p[0] != '/' {
		p = "/" + p
	}
	np := path.Clean(p)
	// path.Clean removes trailing slash except for root;
	// put the trailing slash back if necessary.
	if p[len(p)-1] == '/' && np != "/" {
		np += "/"
	}
	return np
}

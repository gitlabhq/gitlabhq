package urlprefix

import (
	"path"
	"strings"
)

type Prefix string

func (p Prefix) Strip(path string) string {
	return CleanURIPath(strings.TrimPrefix(path, string(p)))
}

func (p Prefix) Match(path string) bool {
	pre := string(p)
	return strings.HasPrefix(path, pre) || path+"/" == pre
}

// Borrowed from: net/http/server.go
// Return the canonical path for p, eliminating . and .. elements.
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

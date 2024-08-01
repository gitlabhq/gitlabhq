package api

import (
	"fmt"
	"net/url"
)

var (
	errDetailsNotSpecified    = fmt.Errorf("gob details not specified")
	errBackendNotSpecified    = fmt.Errorf("gob backend not specified")
	errIncorrectBackendScheme = fmt.Errorf("gob only supports http/https protocols")
)

// GOBSettings holds the configuration for proxying a request to the upstream
// GitLab Observability Backend
type GOBSettings struct {
	// The location of the GitLab Observability Backend (GOB) instance to connect to.
	Backend string `json:"backend"`
	// Any headers (e.g., Authorization) to send with the upstream request
	Headers map[string]string `json:"headers"`
}

// Upstream returns the GitLab Observability Backend location
func (g *GOBSettings) Upstream() (*url.URL, error) {
	if g == nil {
		return nil, errDetailsNotSpecified
	}

	if g.Backend == "" {
		return nil, errBackendNotSpecified
	}

	u, err := url.Parse(g.Backend)
	if err != nil {
		return nil, err
	}

	if u.Scheme != "http" && u.Scheme != "https" {
		return nil, errIncorrectBackendScheme
	}

	return u, nil
}

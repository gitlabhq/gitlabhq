// Package origincheck provides WebSocket Origin header checks for handlers that
// sit behind a proxy which rewrites the Host header.
package origincheck

import (
	"net/http"
	"net/url"
	"slices"
	"strings"
)

// ByForwardedHost returns a WebSocket origin check that compares the Origin
// header against X-Forwarded-Host (set by the HTTP Router / nginx) rather than
// the Host header. This is needed because the HTTP Router rewrites the Host
// header to an internal hostname, causing the default gorilla/websocket origin
// check to reject legitimate browser connections.
//
// X-Forwarded-Host is only trusted when its value is in trustedForwardedHosts,
// since the header is otherwise attacker-controllable. When the header is
// absent, the check falls back to comparing against Host.
func ByForwardedHost(trustedForwardedHosts []string) func(r *http.Request) bool {
	return func(r *http.Request) bool {
		origin := r.Header.Get("Origin")
		if origin == "" {
			return true
		}

		u, err := url.Parse(origin)
		if err != nil {
			return false
		}

		forwardedHost := r.Header.Get("X-Forwarded-Host")
		if forwardedHost == "" {
			return strings.EqualFold(u.Host, r.Host)
		}

		isTrusted := slices.ContainsFunc(trustedForwardedHosts, func(h string) bool {
			return strings.EqualFold(h, forwardedHost)
		})

		return isTrusted && strings.EqualFold(u.Host, forwardedHost)
	}
}

// Package oauthproxy routes OAuth requests between GitLab Rails (Doorkeeper)
// and the IAM Auth service during the AUTH-011 gradual rollout.
package oauthproxy

import (
	"bytes"
	"errors"
	"io"
	"net/http"
	"net/url"
	"strings"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

// maxOAuthBodySize caps the in-memory buffer for /oauth/{token,revoke,introspect}
// bodies. These endpoints are pre-authentication, so an uncapped io.ReadAll would
// let an unauthenticated client force Workhorse to buffer arbitrary memory. Real
// OAuth form payloads sit well under 1 KiB; 1 MiB leaves comfortable headroom.
const maxOAuthBodySize = 1 << 20

// iamTokenPrefixes mark tokens issued by the IAM Auth service so Workhorse can
// route follow-up requests in the same OAuth flow back to IAM without a
// feature-flag check. `ory_` is the prefix Hydra currently emits; `giat_` is
// the planned GitLab IAM prefix once the IAM service migrates. Both are
// matched until that migration lands.
var iamTokenPrefixes = []string{"giat_", "ory_"}

var tokenParamNames = []string{"code", "token", "refresh_token"}

func hasIAMTokenPrefix(value string) bool {
	for _, prefix := range iamTokenPrefixes {
		if strings.HasPrefix(value, prefix) {
			return true
		}
	}
	return false
}

// Handler routes OAuth requests between Rails and the IAM Auth service.
type Handler struct {
	API           *api.API
	Version       string
	RailsProxy    http.Handler
	IAMProxy      http.Handler
	IAMServiceURL *url.URL
}

// BuildAuthorizeRoute returns the http.Handler for /oauth/authorize*.
// Always forwards to Rails until a follow-up MR adds feature-flag-gated routing.
func (h *Handler) BuildAuthorizeRoute() http.Handler {
	if h.IAMServiceURL == nil {
		return h.RailsProxy
	}

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		h.logDecision(r, destinationRails, reasonRuleNotImplemented)
		h.RailsProxy.ServeHTTP(w, r)
	})
}

// BuildTokenRoute returns the http.Handler for /oauth/token, /oauth/revoke,
// and /oauth/introspect. Routes to IAM if any body param carries an
// IAM-prefixed token; otherwise to Rails. Falls back to RailsProxy if
// IAMProxy is nil despite IAMServiceURL being set — a misconfiguration
// degrades gracefully rather than panicking on the first request.
func (h *Handler) BuildTokenRoute() http.Handler {
	if h.IAMServiceURL == nil || h.IAMProxy == nil {
		return h.RailsProxy
	}

	return http.HandlerFunc(h.routeTokenEndpoint)
}

func (h *Handler) routeTokenEndpoint(w http.ResponseWriter, r *http.Request) {
	r.Body = http.MaxBytesReader(w, r.Body, maxOAuthBodySize)
	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			h.logDecision(r, destinationRejected, reasonBodyTooLarge)
			http.Error(w, "request body too large", http.StatusRequestEntityTooLarge)
			return
		}
		h.logDecision(r, destinationRails, reasonBodyReadError)
		h.RailsProxy.ServeHTTP(w, r)
		return
	}
	r.Body = io.NopCloser(bytes.NewReader(bodyBytes))

	params, err := url.ParseQuery(string(bodyBytes))
	if err != nil {
		h.logDecision(r, destinationRails, reasonBodyParseError)
		h.RailsProxy.ServeHTTP(w, r)
		return
	}

	hasAnyTokenParam := false
	for _, name := range tokenParamNames {
		if hasIAMTokenPrefix(params.Get(name)) {
			h.logDecision(r, destinationIAM, reasonIAMTokenPrefixMatch)
			h.IAMProxy.ServeHTTP(w, r)
			return
		}
		if params.Has(name) {
			hasAnyTokenParam = true
		}
	}

	reason := reasonNoTokenParam
	if hasAnyTokenParam {
		reason = reasonDoorkeeperToken
	}
	h.logDecision(r, destinationRails, reason)
	h.RailsProxy.ServeHTTP(w, r)
}

type destination string

const (
	destinationRails    destination = "rails"
	destinationIAM      destination = "iam"
	destinationRejected destination = "rejected"
)

const (
	reasonRuleNotImplemented  = "rule_not_implemented"
	reasonIAMTokenPrefixMatch = "iam_token_prefix_match"
	reasonDoorkeeperToken     = "doorkeeper_token"
	reasonNoTokenParam        = "no_token_param"
	reasonBodyReadError       = "body_read_error"
	reasonBodyParseError      = "body_parse_error"
	reasonBodyTooLarge        = "body_too_large"
)

func (h *Handler) logDecision(r *http.Request, dest destination, reason string) {
	log.WithContextFields(r.Context(), log.Fields{
		"method":      r.Method,
		"path":        r.URL.Path,
		"destination": string(dest),
		"reason":      reason,
	}).Info("oauthproxy: routing decision")
}

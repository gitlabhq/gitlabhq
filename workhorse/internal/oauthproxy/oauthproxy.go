// Package oauthproxy routes OAuth requests between GitLab Rails (Doorkeeper)
// and the IAM Auth service during the AUTH-011 gradual rollout.
package oauthproxy

import (
	"bytes"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

// oauthRoutingPath is the Rails endpoint Workhorse asks for a per-application
// routing decision on `/oauth/authorize*`. See lib/api/internal/workhorse.rb.
const oauthRoutingPath = "/api/v4/internal/workhorse/oauth_routing"

// maxOAuthBodySize caps the in-memory buffer for /oauth/{token,revoke,introspect}
// bodies. These endpoints are pre-authentication, so an uncapped io.ReadAll would
// let an unauthenticated client force Workhorse to buffer arbitrary memory. Real
// OAuth form payloads sit well under 1 KiB; 1 MiB leaves comfortable headroom.
const maxOAuthBodySize = 1 << 20

// maxClientIDLength caps the client_id we forward to the oauth_routing endpoint.
// /oauth/authorize is pre-authentication; without a cap, an oversized query
// client_id would be forwarded to Rails (rejected by its `limit: 255`
// validation) before we fall back and proxy the request to Rails again — two
// internal calls per malformed request. Matches the Rails-side limit so a
// legitimate client_id is never rejected here.
const maxClientIDLength = 255

// iamTokenPrefixes mark tokens issued by the IAM Auth service so Workhorse can
// route follow-up requests in the same OAuth flow back to IAM without a
// feature-flag check. `ory_` is the prefix Hydra currently emits; `giat_` is
// the planned GitLab IAM prefix once the IAM service migrates. Both are
// matched until that migration lands.
var iamTokenPrefixes = []string{"giat_", "ory_"}

var tokenParamNames = []string{"code", "token", "refresh_token"}

// Sentinel errors returned by readFormBody so callers can map a body-handling
// failure to a response without the helper ever touching the ResponseWriter.
var (
	errBodyTooLarge   = errors.New("oauth: request body too large")
	errBodyReadFailed = errors.New("oauth: request body read failed")
	errBodyParseError = errors.New("oauth: request body parse failed")
)

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

// BuildAuthorizeRoute returns the http.Handler for /oauth/authorize and
// /oauth/authorize_device. Extracts the request's client_id (query for GET,
// form body for POST), asks Rails for a per-application routing decision via
// the oauth_routing PreAuthorize endpoint, and forwards to IAM or Rails
// accordingly. Falls back to RailsProxy if the routing dependencies aren't
// wired — a misconfiguration degrades gracefully rather than panicking on
// the first request.
func (h *Handler) BuildAuthorizeRoute() http.Handler {
	if h.IAMServiceURL == nil || h.IAMProxy == nil || h.API == nil {
		return h.RailsProxy
	}

	return http.HandlerFunc(h.routeAuthorizeEndpoint)
}

func (h *Handler) routeAuthorizeEndpoint(w http.ResponseWriter, r *http.Request) {
	// A request carrying an IAM flow verifier is continuing a flow that already
	// started on IAM (post-login / post-consent redirect). Route it back to IAM
	// regardless of feature-flag state — no client_id lookup needed.
	if hasIAMFlowVerifier(r) {
		h.logDecision(r, destinationIAM, reasonIAMFlowVerifier)
		h.IAMProxy.ServeHTTP(w, r)
		return
	}

	clientID, err := extractClientID(w, r)
	if err != nil {
		h.handleBodyError(w, r, err)
		return
	}
	if len(clientID) > maxClientIDLength {
		// Route to Rails without consulting oauth_routing: an oversized
		// client_id can only be rejected by Rails' `limit: 255` anyway, so
		// skip the extra internal call for unauthenticated junk input.
		h.logDecision(r, destinationRails, reasonClientIDTooLong)
		h.RailsProxy.ServeHTTP(w, r)
		return
	}

	destination, err := h.requestRoutingDecision(r, clientID)
	if err != nil {
		// Fail-safe to Rails: a flaky internal API call must not break the
		// OAuth flow that worked yesterday. The error is logged via labkit
		// inside PreAuthorize; we just record the routing decision here.
		h.logDecision(r, destinationRails, reasonPreAuthorizeError)
		h.RailsProxy.ServeHTTP(w, r)
		return
	}

	if destination == string(destinationIAM) {
		h.logDecision(r, destinationIAM, reasonIAMRoutingEnabled)
		h.IAMProxy.ServeHTTP(w, r)
		return
	}
	h.logDecision(r, destinationRails, reasonDoorkeeperFFDisabled)
	h.RailsProxy.ServeHTTP(w, r)
}

// hasIAMFlowVerifier reports whether the request carries an IAM flow verifier
// query parameter. IAM sets these on the redirect back to /oauth/authorize, so
// they arrive in the query string for both GET and the device POST.
func hasIAMFlowVerifier(r *http.Request) bool {
	query := r.URL.Query()
	for _, p := range iamFlowVerifierParams {
		if query.Get(p) != "" {
			return true
		}
	}
	return false
}

// extractClientID returns the request's client_id. GET /oauth/authorize carries
// it in the query string; POST /oauth/authorize_device carries it in the form
// body, which is read via readFormBody (capped and replayed). It never writes to
// w — on a body-handling failure it returns one of the errBody* sentinels for
// the caller to map to a response via handleBodyError.
func extractClientID(w http.ResponseWriter, r *http.Request) (string, error) {
	if r.Method != http.MethodPost {
		return r.URL.Query().Get("client_id"), nil
	}
	params, err := readFormBody(w, r)
	if err != nil {
		return "", err
	}
	return params.Get("client_id"), nil
}

// readFormBody caps and reads the request body, replays it onto r so a
// downstream handler can still consume it, and parses it as form params.
//
// It never writes a response. The w parameter is required only by
// http.MaxBytesReader, which uses it to manage the connection when the cap is
// exceeded; readFormBody itself does not write to it. Replacing r.Body is the
// intentional body-replay both callers rely on, not a response side effect. On
// failure it returns errBodyTooLarge / errBodyReadFailed / errBodyParseError for
// the caller to map to a response.
func readFormBody(w http.ResponseWriter, r *http.Request) (url.Values, error) {
	r.Body = http.MaxBytesReader(w, r.Body, maxOAuthBodySize)
	bodyBytes, err := io.ReadAll(r.Body)
	if err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			return nil, errBodyTooLarge
		}
		return nil, errBodyReadFailed
	}
	r.Body = io.NopCloser(bytes.NewReader(bodyBytes))

	params, err := url.ParseQuery(string(bodyBytes))
	if err != nil {
		return nil, errBodyParseError
	}
	return params, nil
}

// handleBodyError renders the response for a readFormBody failure: 413 for an
// oversized body, otherwise a fail-safe proxy to Rails.
func (h *Handler) handleBodyError(w http.ResponseWriter, r *http.Request, err error) {
	switch {
	case errors.Is(err, errBodyTooLarge):
		h.logDecision(r, destinationRejected, reasonBodyTooLarge)
		http.Error(w, "request body too large", http.StatusRequestEntityTooLarge)
	case errors.Is(err, errBodyParseError):
		h.logDecision(r, destinationRails, reasonBodyParseError)
		h.RailsProxy.ServeHTTP(w, r)
	default: // errBodyReadFailed
		h.logDecision(r, destinationRails, reasonBodyReadError)
		h.RailsProxy.ServeHTTP(w, r)
	}
}

// requestRoutingDecision asks the Rails oauth_routing endpoint where to send
// this authorize request. It clones r so the client_id can be placed in the
// query string (where Grape's `optional :client_id` picks it up) — for POST
// /oauth/authorize_device the client_id lives in the body, not the query —
// without disturbing the live request's RawQuery, which is still forwarded to
// the chosen backend afterwards.
func (h *Handler) requestRoutingDecision(r *http.Request, clientID string) (string, error) {
	routingReq := r.Clone(r.Context())
	routingReq.URL.RawQuery = url.Values{"client_id": {clientID}}.Encode()

	decision, err := h.API.PreAuthorizeFixedPath(routingReq, http.MethodPost, oauthRoutingPath)
	if err != nil {
		return "", fmt.Errorf("oauth_routing: %w", err)
	}
	return decision.Destination, nil
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
	params, err := readFormBody(w, r)
	if err != nil {
		h.handleBodyError(w, r, err)
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
	reasonIAMTokenPrefixMatch  = "iam_token_prefix_match"
	reasonIAMRoutingEnabled    = "iam_routing_enabled"
	reasonDoorkeeperToken      = "doorkeeper_token"
	reasonDoorkeeperFFDisabled = "doorkeeper_ff_disabled"
	reasonNoTokenParam         = "no_token_param" // #nosec G101 -- routing-decision log reason, not a credential
	reasonBodyReadError        = "body_read_error"
	reasonBodyParseError       = "body_parse_error"
	reasonBodyTooLarge         = "body_too_large"
	reasonPreAuthorizeError    = "preauthorize_error"
	reasonClientIDTooLong      = "client_id_too_long"
	reasonIAMFlowVerifier      = "iam_flow_verifier"
)

// iamFlowVerifierParams are query parameters the IAM Auth service sets when it
// redirects the user agent back to /oauth/authorize to continue an
// IAM-initiated flow (after login or consent). Their presence means the flow
// already started on IAM, so the request must be routed back to IAM regardless
// of feature-flag state to preserve flow continuity. See the IAM service's
// handleAuthorize (gitlab-org/auth/iam, auth/oauth/server/handler.go).
var iamFlowVerifierParams = []string{"login_verifier", "consent_verifier"}

func (h *Handler) logDecision(r *http.Request, dest destination, reason string) {
	log.WithContextFields(r.Context(), log.Fields{
		"method":      r.Method,
		"path":        r.URL.Path,
		"destination": string(dest),
		"reason":      reason,
	}).Info("oauthproxy: routing decision")
}

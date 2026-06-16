package oauthproxy

import (
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

// recordingHandler captures invocation count and request body so tests can
// verify which proxy received the request and that the body survived the
// read-and-replay cycle in routeTokenEndpoint.
type recordingHandler struct {
	called   int
	lastBody string
}

func (h *recordingHandler) ServeHTTP(_ http.ResponseWriter, r *http.Request) {
	h.called++
	if r.Body != nil {
		body, _ := io.ReadAll(r.Body)
		h.lastBody = string(body)
	}
}

func newTestHandler() (*Handler, *recordingHandler, *recordingHandler) {
	rails := &recordingHandler{}
	iam := &recordingHandler{}
	iamURL, _ := url.Parse("http://iam.test:8084")
	return &Handler{RailsProxy: rails, IAMProxy: iam, IAMServiceURL: iamURL}, rails, iam
}

func formPost(path, body string) *http.Request {
	r := httptest.NewRequest(http.MethodPost, path, strings.NewReader(body))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
	return r
}

// === BuildAuthorizeRoute ===

func TestBuildAuthorizeRoute_ReturnsRailsProxyUnchangedWhenIAMURLIsNil(t *testing.T) {
	rails := &recordingHandler{}
	built := (&Handler{RailsProxy: rails}).BuildAuthorizeRoute()

	// Zero-overhead invariant: when IAM routing is off, return the exact
	// RailsProxy with no wrapper.
	require.Same(t, rails, built)
}

func TestBuildAuthorizeRoute_FallsThroughToRailsWhenIAMURLIsSet(t *testing.T) {
	h, rails, iam := newTestHandler()
	built := h.BuildAuthorizeRoute()

	built.ServeHTTP(httptest.NewRecorder(), httptest.NewRequest(http.MethodGet, "/oauth/authorize", nil))

	require.Equal(t, 1, rails.called, "authorize must forward to Rails until MR 4 adds FF-gated routing")
	require.Equal(t, 0, iam.called)
}

// === BuildTokenRoute ===

func TestBuildTokenRoute_ReturnsRailsProxyUnchangedWhenIAMURLIsNil(t *testing.T) {
	rails := &recordingHandler{}
	built := (&Handler{RailsProxy: rails}).BuildTokenRoute()

	require.Same(t, rails, built)
}

func TestBuildTokenRoute_FallsBackToRailsWhenIAMProxyIsNil(t *testing.T) {
	rails := &recordingHandler{}
	iamURL, _ := url.Parse("http://iam.test:8084")
	// IAMServiceURL set but IAMProxy left nil: misconfiguration must degrade
	// to RailsProxy at build time rather than panic on the first request.
	built := (&Handler{RailsProxy: rails, IAMServiceURL: iamURL}).BuildTokenRoute()

	require.Same(t, rails, built)
}

func TestBuildTokenRoute_Routing(t *testing.T) {
	tests := []struct {
		name    string
		path    string
		body    string
		wantIAM bool
	}{
		{"code giat_ prefix", "/oauth/token", "grant_type=authorization_code&code=giat_abc123", true},
		{"refresh_token giat_ prefix", "/oauth/token", "grant_type=refresh_token&refresh_token=giat_xyz789", true},
		{"token giat_ prefix (revoke)", "/oauth/revoke", "token=giat_revokeme", true},
		{"code ory_ prefix", "/oauth/token", "grant_type=authorization_code&code=ory_abc123", true},
		{"token ory_ prefix (introspect)", "/oauth/introspect", "token=ory_introspectme", true},
		{"doorkeeper code", "/oauth/token", "grant_type=authorization_code&code=plain_doorkeeper_code", false},
		{"doorkeeper token", "/oauth/introspect", "token=plain_doorkeeper_token", false},
		{"empty body", "/oauth/token", "", false},
		{"empty token value", "/oauth/token", "grant_type=authorization_code&code=", false},
		{"no token-bearing param", "/oauth/token", "grant_type=client_credentials&client_id=demo", false},
		// Malformed percent-encoding makes url.ParseQuery fail; the handler
		// must fall back to Rails with the body intact rather than crash.
		{"malformed body", "/oauth/token", "code=%zz", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			h, rails, iam := newTestHandler()
			built := h.BuildTokenRoute()

			var req *http.Request
			if tt.body == "" {
				req = httptest.NewRequest(http.MethodPost, tt.path, nil)
			} else {
				req = formPost(tt.path, tt.body)
			}

			built.ServeHTTP(httptest.NewRecorder(), req)

			if tt.wantIAM {
				require.Equal(t, 1, iam.called, "expected request to go to IAM")
				require.Equal(t, 0, rails.called)
				require.Equal(t, tt.body, iam.lastBody, "body must be preserved on the IAM path")
			} else {
				require.Equal(t, 1, rails.called, "expected request to go to Rails")
				require.Equal(t, 0, iam.called)
				require.Equal(t, tt.body, rails.lastBody, "body must be preserved on the Rails path")
			}
		})
	}
}

func TestBuildTokenRoute_RejectsOversizedBody(t *testing.T) {
	h, rails, iam := newTestHandler()
	built := h.BuildTokenRoute()

	// Body exceeds the pre-auth cap. The handler must reject with 413 instead
	// of buffering the whole payload or forwarding to either backend.
	body := strings.Repeat("x", maxOAuthBodySize+1)
	req := formPost("/oauth/token", body)
	rec := httptest.NewRecorder()

	built.ServeHTTP(rec, req)

	require.Equal(t, http.StatusRequestEntityTooLarge, rec.Code)
	require.Equal(t, 0, rails.called, "oversized body must not reach Rails")
	require.Equal(t, 0, iam.called, "oversized body must not reach IAM")
}

func TestBuildTokenRoute_RoutesToRailsWhenBodyReadFails(t *testing.T) {
	h, rails, iam := newTestHandler()
	built := h.BuildTokenRoute()

	// Substitute a body that returns an error on first Read.
	req := httptest.NewRequest(http.MethodPost, "/oauth/token", &erroringReader{})

	built.ServeHTTP(httptest.NewRecorder(), req)

	require.Equal(t, 1, rails.called, "body-read errors fall back to Rails (safe default)")
	require.Equal(t, 0, iam.called)
}

type erroringReader struct{}

func (*erroringReader) Read(_ []byte) (int, error) { return 0, io.ErrUnexpectedEOF }
func (*erroringReader) Close() error               { return nil }

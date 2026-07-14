package oauthproxy

import (
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

const (
	decisionRailsBody = `{"destination":"rails"}`
	decisionIAMBody   = `{"destination":"iam"}`
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

func TestBuildAuthorizeRoute_FallsBackToRailsWhenDependenciesMissing(t *testing.T) {
	tests := []struct {
		name    string
		handler *Handler
	}{
		{
			name:    "IAMProxy nil",
			handler: &Handler{RailsProxy: &recordingHandler{}, API: &api.API{}, IAMServiceURL: mustURL(t, "http://iam.test:8084")},
		},
		{
			name:    "API nil",
			handler: &Handler{RailsProxy: &recordingHandler{}, IAMProxy: &recordingHandler{}, IAMServiceURL: mustURL(t, "http://iam.test:8084")},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Misconfigurations must degrade to RailsProxy at build time
			// rather than panic on the first request.
			require.Same(t, tt.handler.RailsProxy, tt.handler.BuildAuthorizeRoute())
		})
	}
}

func TestBuildAuthorizeRoute_Routing(t *testing.T) {
	tests := []struct {
		name     string
		method   string
		path     string
		query    string
		body     string
		decision string // what the routing endpoint returns; "" means no client_id seen
		wantIAM  bool
	}{
		{
			name: "GET authorize, FF enabled for client_id", method: http.MethodGet,
			path: "/oauth/authorize", query: "client_id=app-uid-1&response_type=code",
			decision: "iam", wantIAM: true,
		},
		{
			name: "GET authorize, FF disabled for client_id", method: http.MethodGet,
			path: "/oauth/authorize", query: "client_id=app-uid-2&response_type=code",
			decision: "rails", wantIAM: false,
		},
		{
			name: "GET authorize, missing client_id falls through to Rails decision", method: http.MethodGet,
			path: "/oauth/authorize", query: "response_type=code",
			decision: "rails", wantIAM: false,
		},
		{
			name: "POST authorize_device, FF enabled for client_id", method: http.MethodPost,
			path: "/oauth/authorize_device", body: "client_id=app-uid-3&scope=read",
			decision: "iam", wantIAM: true,
		},
		{
			name: "POST authorize_device, FF disabled for client_id", method: http.MethodPost,
			path: "/oauth/authorize_device", body: "client_id=app-uid-4&scope=read",
			decision: "rails", wantIAM: false,
		},
		{
			name: "unknown destination string falls back to Rails", method: http.MethodGet,
			path: "/oauth/authorize", query: "client_id=app-uid-5",
			decision: "somewhere-else", wantIAM: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var seenClientID string
			h, rails, iam := newAuthorizeTestHandler(t, func(r *http.Request) (int, string) {
				seenClientID = r.URL.Query().Get("client_id")
				return http.StatusOK, fmt.Sprintf(`{"destination":%q}`, tt.decision)
			})

			req := buildAuthorizeRequest(tt.method, tt.path, tt.query, tt.body)
			h.BuildAuthorizeRoute().ServeHTTP(httptest.NewRecorder(), req)

			if tt.wantIAM {
				require.Equal(t, 1, iam.called, "expected request to go to IAM")
				require.Equal(t, 0, rails.called)
				if tt.body != "" {
					require.Equal(t, tt.body, iam.lastBody, "POST body must be preserved on the IAM path")
				}
			} else {
				require.Equal(t, 1, rails.called, "expected request to go to Rails")
				require.Equal(t, 0, iam.called)
				if tt.body != "" {
					require.Equal(t, tt.body, rails.lastBody, "POST body must be preserved on the Rails path")
				}
			}

			// The routing endpoint sees client_id in its query string regardless
			// of where it appeared in the original request (query vs body).
			wantClientID := expectedClientID(tt.query, tt.body)
			require.Equal(t, wantClientID, seenClientID,
				"client_id must reach the routing endpoint as a query parameter")
		})
	}
}

func TestBuildAuthorizeRoute_FallsBackToRailsWhenPreAuthorizeFails(t *testing.T) {
	h, rails, iam := newAuthorizeTestHandler(t, func(_ *http.Request) (int, string) {
		return http.StatusInternalServerError, ""
	})

	req := buildAuthorizeRequest(http.MethodGet, "/oauth/authorize", "client_id=app-uid-x", "")
	h.BuildAuthorizeRoute().ServeHTTP(httptest.NewRecorder(), req)

	require.Equal(t, 1, rails.called, "PreAuthorize errors fall back to Rails (safe default)")
	require.Equal(t, 0, iam.called)
}

func TestBuildAuthorizeRoute_RejectsOversizedPOSTBody(t *testing.T) {
	h, rails, iam := newAuthorizeTestHandler(t, func(_ *http.Request) (int, string) {
		return http.StatusOK, decisionRailsBody
	})

	body := strings.Repeat("x", maxOAuthBodySize+1)
	req := formPost("/oauth/authorize_device", body)
	rec := httptest.NewRecorder()

	h.BuildAuthorizeRoute().ServeHTTP(rec, req)

	require.Equal(t, http.StatusRequestEntityTooLarge, rec.Code)
	require.Equal(t, 0, rails.called, "oversized body must not reach Rails")
	require.Equal(t, 0, iam.called, "oversized body must not reach IAM")
}

func TestBuildAuthorizeRoute_FlowVerifierRoutesToIAMWithoutPreAuthorize(t *testing.T) {
	tests := []struct {
		name  string
		query string
	}{
		{"login_verifier", "login_verifier=lv_abc&client_id=app-uid-1"},
		{"consent_verifier", "consent_verifier=cv_xyz&client_id=app-uid-1"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			routingCalls := 0
			h, rails, iam := newAuthorizeTestHandler(t, func(_ *http.Request) (int, string) {
				routingCalls++
				return http.StatusOK, decisionRailsBody
			})

			req := buildAuthorizeRequest(http.MethodGet, "/oauth/authorize", tt.query, "")
			h.BuildAuthorizeRoute().ServeHTTP(httptest.NewRecorder(), req)

			require.Equal(t, 0, routingCalls, "a flow verifier must route to IAM without an oauth_routing call")
			require.Equal(t, 1, iam.called, "flow verifier routes to IAM regardless of FF")
			require.Equal(t, 0, rails.called)
		})
	}
}

func TestBuildAuthorizeRoute_OversizedClientIDRoutesToRailsWithoutPreAuthorize(t *testing.T) {
	oversized := strings.Repeat("a", maxClientIDLength+1)

	tests := []struct {
		name   string
		method string
		path   string
		query  string
		body   string
	}{
		{"GET", http.MethodGet, "/oauth/authorize", "client_id=" + oversized, ""},
		{"POST", http.MethodPost, "/oauth/authorize_device", "", "client_id=" + oversized},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			routingCalls := 0
			h, rails, iam := newAuthorizeTestHandler(t, func(_ *http.Request) (int, string) {
				routingCalls++
				return http.StatusOK, decisionIAMBody
			})

			req := buildAuthorizeRequest(tt.method, tt.path, tt.query, tt.body)
			h.BuildAuthorizeRoute().ServeHTTP(httptest.NewRecorder(), req)

			require.Equal(t, 0, routingCalls, "oversized client_id must not trigger an oauth_routing call")
			require.Equal(t, 1, rails.called, "oversized client_id falls back to Rails")
			require.Equal(t, 0, iam.called, "oversized client_id must not reach IAM")
		})
	}
}

func TestBuildAuthorizeRoute_RoutesToRailsWhenPOSTBodyReadFails(t *testing.T) {
	h, rails, iam := newAuthorizeTestHandler(t, func(_ *http.Request) (int, string) {
		return http.StatusOK, decisionRailsBody
	})

	req := httptest.NewRequest(http.MethodPost, "/oauth/authorize_device", &erroringReader{})
	h.BuildAuthorizeRoute().ServeHTTP(httptest.NewRecorder(), req)

	require.Equal(t, 1, rails.called, "body-read errors fall back to Rails (safe default)")
	require.Equal(t, 0, iam.called)
}

// newAuthorizeTestHandler returns a Handler wired against an httptest server
// that impersonates the oauth_routing endpoint. The decisionFn callback lets
// each test control the response (status + body) and inspect the inbound
// request — e.g. to verify client_id propagation.
func newAuthorizeTestHandler(t *testing.T, decisionFn func(r *http.Request) (status int, body string)) (*Handler, *recordingHandler, *recordingHandler) {
	t.Helper()

	// api.PreAuthorize signs outbound requests via secret.RoundTripper, which
	// requires the test secret file to be wired up.
	testhelper.ConfigureSecret()

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != oauthRoutingPath {
			w.WriteHeader(http.StatusNotFound)
			return
		}
		status, body := decisionFn(r)
		w.Header().Set("Content-Type", api.ResponseContentType)
		w.WriteHeader(status)
		_, _ = io.WriteString(w, body)
	}))
	t.Cleanup(ts.Close)

	rails := &recordingHandler{}
	iam := &recordingHandler{}
	h := &Handler{
		RailsProxy:    rails,
		IAMProxy:      iam,
		IAMServiceURL: mustURL(t, "http://iam.test:8084"),
		API:           api.NewAPI(helper.URLMustParse(ts.URL), "test", http.DefaultTransport),
	}
	return h, rails, iam
}

func buildAuthorizeRequest(method, path, query, body string) *http.Request {
	target := path
	if query != "" {
		target = path + "?" + query
	}
	if method == http.MethodPost {
		r := httptest.NewRequest(method, target, strings.NewReader(body))
		r.Header.Set("Content-Type", "application/x-www-form-urlencoded")
		return r
	}
	return httptest.NewRequest(method, target, nil)
}

func expectedClientID(query, body string) string {
	if query != "" {
		if v, err := url.ParseQuery(query); err == nil {
			return v.Get("client_id")
		}
	}
	if body != "" {
		if v, err := url.ParseQuery(body); err == nil {
			return v.Get("client_id")
		}
	}
	return ""
}

func mustURL(t *testing.T, raw string) *url.URL {
	t.Helper()
	u, err := url.Parse(raw)
	require.NoError(t, err)
	return u
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

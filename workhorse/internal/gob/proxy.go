// Package gob manages request proxies to GitLab Observability Backend
package gob

import (
	"fmt"
	"net/http"
	"regexp"
	"time"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	proxypkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
)

// Internal endpoint namespace for observability authorization
const gobInternalProjectAuthPath = "/api/v4/internal/observability/project/"

var projectPathRegex = regexp.MustCompile(`^/api/v4/projects/([^/]+)`)

// Proxy manages the authorization and upstream connection to
// GitLab Observability Backend
type Proxy struct {
	version             string
	api                 *api.API
	proxyHeadersTimeout time.Duration
	developmentMode     bool
}

// NewProxy returns a new Proxy for connecting to GitLab Observability Backend
func NewProxy(
	api *api.API,
	version string,
	proxyHeadersTimeout time.Duration,
	cfg config.Config) *Proxy {
	return &Proxy{
		api:                 api,
		version:             version,
		proxyHeadersTimeout: proxyHeadersTimeout,
		developmentMode:     cfg.DevelopmentMode,
	}
}

// WithProjectAuth configures the proxy to use a Rails API path for authorization
func (p *Proxy) WithProjectAuth(path string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if p.api.URL == nil {
			fail.Request(w, r, fmt.Errorf("api URL has not been set"))
			return
		}
		authURL := *p.api.URL

		projectID, err := extractProjectID(r)
		if err != nil {
			fail.Request(w, r, err)
			return
		}
		authURL.Path = gobInternalProjectAuthPath + projectID + path

		authReq := &http.Request{
			Method: r.Method,
			URL:    &authURL,
			Header: r.Header.Clone(),
		}
		authReq = authReq.WithContext(r.Context())

		authorizer := p.api.PreAuthorizeHandler(func(_ http.ResponseWriter, _ *http.Request, a *api.Response) {
			// Successful authorization
			p.serveHTTP(w, r, a)
		}, "")
		authorizer.ServeHTTP(w, authReq)
	})
}

func (p *Proxy) serveHTTP(w http.ResponseWriter, r *http.Request, a *api.Response) {
	backend, err := a.Gob.Upstream()
	if err != nil {
		fail.Request(w, r, err)
		return
	}
	// Remove prefix from path so it matches the cloud.gitlab.com/observability/ routing layer.
	// https://gitlab.com/gitlab-com/gl-infra/production-engineering/-/issues/25077
	outReq := r.Clone(r.Context())
	outReq.URL.Path = projectPathRegex.ReplaceAllLiteralString(r.URL.EscapedPath(), "")

	rt := secret.NewRoundTripper(
		roundtripper.NewBackendRoundTripper(
			backend,
			"",
			p.proxyHeadersTimeout,
			p.developmentMode,
		), p.version)

	pxy := proxypkg.NewProxy(
		backend,
		p.version,
		rt,
		proxypkg.WithCustomHeaders(a.Gob.Headers),
		proxypkg.WithForcedTargetHostHeader(),
	)
	pxy.ServeHTTP(w, outReq)
}

func extractProjectID(r *http.Request) (string, error) {
	matches := projectPathRegex.FindStringSubmatch(r.URL.EscapedPath())
	if len(matches) != 2 {
		return "", fmt.Errorf("%s does not match expected %s", r.URL.EscapedPath(), projectPathRegex.String())
	}
	return matches[1], nil
}

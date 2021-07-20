/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package upstream

import (
	"fmt"
	"os"

	"net/http"
	"strings"

	"github.com/sirupsen/logrus"
	"gitlab.com/gitlab-org/labkit/correlation"

	apipkg "gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/rejectmethods"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/upload"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/upstream/roundtripper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/urlprefix"
)

var (
	DefaultBackend         = helper.URLMustParse("http://localhost:8080")
	requestHeaderBlacklist = []string{
		upload.RewrittenFieldsHeader,
	}
)

type upstream struct {
	config.Config
	URLPrefix             urlprefix.Prefix
	Routes                []routeEntry
	RoundTripper          http.RoundTripper
	CableRoundTripper     http.RoundTripper
	APIClient             *apipkg.API
	accessLogger          *logrus.Logger
	enableGeoProxyFeature bool
}

func NewUpstream(cfg config.Config, accessLogger *logrus.Logger) http.Handler {
	return newUpstream(cfg, accessLogger, configureRoutes)
}

func newUpstream(cfg config.Config, accessLogger *logrus.Logger, routesCallback func(*upstream)) http.Handler {
	up := upstream{
		Config:       cfg,
		accessLogger: accessLogger,
	}
	if up.Backend == nil {
		up.Backend = DefaultBackend
	}
	if up.CableBackend == nil {
		up.CableBackend = up.Backend
	}
	if up.CableSocket == "" {
		up.CableSocket = up.Socket
	}
	up.RoundTripper = roundtripper.NewBackendRoundTripper(up.Backend, up.Socket, up.ProxyHeadersTimeout, cfg.DevelopmentMode)
	up.CableRoundTripper = roundtripper.NewBackendRoundTripper(up.CableBackend, up.CableSocket, up.ProxyHeadersTimeout, cfg.DevelopmentMode)
	up.configureURLPrefix()
	up.APIClient = apipkg.NewAPI(
		up.Backend,
		up.Version,
		up.RoundTripper,
	)
	// Kind of a feature flag. See https://gitlab.com/groups/gitlab-org/-/epics/5914#note_564974130
	up.enableGeoProxyFeature = os.Getenv("GEO_SECONDARY_PROXY") == "1"
	routesCallback(&up)

	var correlationOpts []correlation.InboundHandlerOption
	if cfg.PropagateCorrelationID {
		correlationOpts = append(correlationOpts, correlation.WithPropagation())
	}

	handler := correlation.InjectCorrelationID(&up, correlationOpts...)
	// TODO: move to LabKit https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/339
	handler = rejectmethods.NewMiddleware(handler)
	return handler
}

func (u *upstream) configureURLPrefix() {
	relativeURLRoot := u.Backend.Path
	if !strings.HasSuffix(relativeURLRoot, "/") {
		relativeURLRoot += "/"
	}
	u.URLPrefix = urlprefix.Prefix(relativeURLRoot)
}

func (u *upstream) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	helper.FixRemoteAddr(r)

	helper.DisableResponseBuffering(w)

	// Drop RequestURI == "*" (FIXME: why?)
	if r.RequestURI == "*" {
		helper.HTTPError(w, r, "Connection upgrade not allowed", http.StatusBadRequest)
		return
	}

	// Disallow connect
	if r.Method == "CONNECT" {
		helper.HTTPError(w, r, "CONNECT not allowed", http.StatusBadRequest)
		return
	}

	// Check URL Root
	URIPath := urlprefix.CleanURIPath(r.URL.EscapedPath())
	prefix := u.URLPrefix
	if !prefix.Match(URIPath) {
		helper.HTTPError(w, r, fmt.Sprintf("Not found %q", URIPath), http.StatusNotFound)
		return
	}

	// Look for a matching route
	var route *routeEntry

	if u.enableGeoProxyFeature {
		geoProxyURL, err := u.APIClient.GetGeoProxyURL()

		if err == nil {
			log.WithRequest(r).WithFields(log.Fields{"geoProxyURL": geoProxyURL}).Info("Geo Proxy: Set route according to Geo Proxy logic")
		} else if err != apipkg.ErrNotGeoSecondary {
			log.WithRequest(r).WithError(err).Error("Geo Proxy: Unable to determine Geo Proxy URL. Falling back to normal routing")
		}
	}

	for _, ro := range u.Routes {
		if ro.isMatch(prefix.Strip(URIPath), r) {
			route = &ro
			break
		}
	}

	if route == nil {
		// The protocol spec in git/Documentation/technical/http-protocol.txt
		// says we must return 403 if no matching service is found.
		helper.HTTPError(w, r, "Forbidden", http.StatusForbidden)
		return
	}

	for _, h := range requestHeaderBlacklist {
		r.Header.Del(h)
	}

	route.handler.ServeHTTP(w, r)
}

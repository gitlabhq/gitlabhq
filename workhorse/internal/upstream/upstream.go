/*
The upstream type implements http.Handler.

In this file we handle request routing and interaction with the authBackend.
*/

package upstream

import (
	"fmt"
	"os"
	"sync"

	"net/http"
	"net/url"
	"strings"

	"github.com/sirupsen/logrus"

	"gitlab.com/gitlab-org/labkit/correlation"

	apipkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	proxypkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/rejectmethods"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/urlprefix"
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
	geoProxyBackend       *url.URL
	geoLocalRoutes        []routeEntry
	geoProxyCableRoute    routeEntry
	geoProxyRoute         routeEntry
	accessLogger          *logrus.Logger
	enableGeoProxyFeature bool
	mu                    sync.RWMutex
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
	if cfg.TrustedCIDRsForPropagation != nil {
		correlationOpts = append(correlationOpts, correlation.WithCIDRsTrustedForPropagation(cfg.TrustedCIDRsForPropagation))
	}
	if cfg.TrustedCIDRsForXForwardedFor != nil {
		correlationOpts = append(correlationOpts, correlation.WithCIDRsTrustedForXForwardedFor(cfg.TrustedCIDRsForXForwardedFor))
	}

	handler := correlation.InjectCorrelationID(&up, correlationOpts...)
	// TODO: move to LabKit https://gitlab.com/gitlab-org/gitlab/-/issues/324823
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

	cleanedPath := prefix.Strip(URIPath)

	route := u.findRoute(cleanedPath, r)

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

func (u *upstream) findRoute(cleanedPath string, r *http.Request) *routeEntry {
	if u.enableGeoProxyFeature {
		if route := u.findGeoProxyRoute(cleanedPath, r); route != nil {
			return route
		}
	}

	for _, ro := range u.Routes {
		if ro.isMatch(cleanedPath, r) {
			return &ro
		}
	}

	return nil
}

func (u *upstream) findGeoProxyRoute(cleanedPath string, r *http.Request) *routeEntry {
	geoProxyURL, err := u.APIClient.GetGeoProxyURL()

	if err == nil {
		u.setGeoProxyRoutes(geoProxyURL)
		return u.matchGeoProxyRoute(cleanedPath, r)
	} else if err != apipkg.ErrNotGeoSecondary {
		log.WithRequest(r).WithError(err).Error("Geo Proxy: Unable to determine Geo Proxy URL. Falling back to normal routing")
	}

	return nil
}

func (u *upstream) matchGeoProxyRoute(cleanedPath string, r *http.Request) *routeEntry {
	// Some routes are safe to serve from this GitLab instance
	for _, ro := range u.geoLocalRoutes {
		if ro.isMatch(cleanedPath, r) {
			log.WithRequest(r).Debug("Geo Proxy: Handle this request locally")
			return &ro
		}
	}

	log.WithRequest(r).WithFields(log.Fields{"geoProxyBackend": u.geoProxyBackend}).Debug("Geo Proxy: Forward this request")

	u.mu.RLock()
	defer u.mu.RUnlock()
	if cleanedPath == "/-/cable" {
		return &u.geoProxyCableRoute
	}

	return &u.geoProxyRoute
}

func (u *upstream) setGeoProxyRoutes(geoProxyURL *url.URL) {
	u.mu.Lock()
	defer u.mu.Unlock()
	if u.geoProxyBackend == nil || u.geoProxyBackend.String() != geoProxyURL.String() {
		log.WithFields(log.Fields{"geoProxyURL": geoProxyURL}).Debug("Geo Proxy: Update GeoProxyRoute")
		u.geoProxyBackend = geoProxyURL
		geoProxyRoundTripper := roundtripper.NewBackendRoundTripper(u.geoProxyBackend, "", u.ProxyHeadersTimeout, u.DevelopmentMode)
		geoProxyUpstream := proxypkg.NewProxy(u.geoProxyBackend, u.Version, geoProxyRoundTripper)
		u.geoProxyCableRoute = u.wsRoute(`^/-/cable\z`, geoProxyUpstream)
		u.geoProxyRoute = u.route("", "", geoProxyUpstream)
	}
}

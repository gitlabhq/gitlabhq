/*
Package upstream implements handlers for handling upstream requests.

The upstream package provides functionality for routing requests and interacting with backend servers.
*/
package upstream

import (
	"fmt"
	"os"
	"sync"
	"time"

	"net/http"
	"net/url"
	"strings"

	"github.com/sebest/xff"
	"github.com/sirupsen/logrus"

	"gitlab.com/gitlab-org/labkit/correlation"

	apipkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/builds"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/nginx"
	proxypkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/rejectmethods"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upstream/roundtripper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/urlprefix"
)

var (
	// DefaultBackend is the default URL for the backend.
	DefaultBackend         = helper.URLMustParse("http://localhost:8080")
	requestHeaderBlacklist = []string{
		upload.RewrittenFieldsHeader,
	}
	geoProxyAPIPollingInterval = 10 * time.Second
)

type upstream struct {
	config.Config
	URLPrefix             urlprefix.Prefix
	Routes                []routeEntry
	RoundTripper          http.RoundTripper
	CableRoundTripper     http.RoundTripper
	APIClient             *apipkg.API
	geoProxyBackend       *url.URL
	geoProxyExtraData     string
	geoLocalRoutes        []routeEntry
	geoProxyCableRoute    routeEntry
	geoProxyRoute         routeEntry
	geoProxyPollSleep     func(time.Duration)
	geoPollerDone         chan struct{}
	accessLogger          *logrus.Logger
	enableGeoProxyFeature bool
	mu                    sync.RWMutex
	watchKeyHandler       builds.WatchKeyHandler
}

// NewUpstream creates a new HTTP handler for handling upstream requests based on the provided configuration.
func NewUpstream(cfg config.Config, accessLogger *logrus.Logger, watchKeyHandler builds.WatchKeyHandler) http.Handler {
	return newUpstream(cfg, accessLogger, configureRoutes, watchKeyHandler)
}

func newUpstream(cfg config.Config, accessLogger *logrus.Logger, routesCallback func(*upstream), watchKeyHandler builds.WatchKeyHandler) http.Handler {
	up := upstream{
		Config:       cfg,
		accessLogger: accessLogger,
		// Kind of a feature flag. See https://gitlab.com/groups/gitlab-org/-/epics/5914#note_564974130
		enableGeoProxyFeature: os.Getenv("GEO_SECONDARY_PROXY") != "0",
		geoProxyBackend:       &url.URL{},
		watchKeyHandler:       watchKeyHandler,
	}
	if up.geoProxyPollSleep == nil {
		up.geoProxyPollSleep = time.Sleep
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
	up.geoPollerDone = make(chan struct{})
	up.RoundTripper = roundtripper.NewBackendRoundTripper(up.Backend, up.Socket, up.ProxyHeadersTimeout, cfg.DevelopmentMode)
	up.CableRoundTripper = roundtripper.NewBackendRoundTripper(up.CableBackend, up.CableSocket, up.ProxyHeadersTimeout, cfg.DevelopmentMode)
	up.configureURLPrefix()
	up.APIClient = apipkg.NewAPI(
		up.Backend,
		up.Version,
		up.RoundTripper,
	)

	routesCallback(&up)

	go up.pollGeoProxyAPI()

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
	fixRemoteAddr(r)

	nginx.DisableResponseBuffering(w)

	// Drop RequestURI == "*" (FIXME: why?)
	if r.RequestURI == "*" {
		httpError(w, r, "Connection upgrade not allowed", http.StatusBadRequest)
		return
	}

	// Disallow connect
	if r.Method == "CONNECT" {
		httpError(w, r, "CONNECT not allowed", http.StatusBadRequest)
		return
	}

	// Check URL Root
	URIPath := urlprefix.CleanURIPath(r.URL.EscapedPath())
	prefix := u.URLPrefix
	if !prefix.Match(URIPath) {
		httpError(w, r, fmt.Sprintf("Not found %q", URIPath), http.StatusNotFound)
		return
	}

	cleanedPath := prefix.Strip(URIPath)

	route := u.findRoute(cleanedPath, r)

	if route == nil {
		// The protocol spec in git/Documentation/technical/http-protocol.txt
		// says we must return 403 if no matching service is found.
		httpError(w, r, "Forbidden", http.StatusForbidden)
		return
	}

	for _, h := range requestHeaderBlacklist {
		r.Header.Del(h)
	}

	route.handler.ServeHTTP(w, r)
}

func (u *upstream) findRoute(cleanedPath string, r *http.Request) *routeEntry {
	if route := u.findGeoProxyRoute(cleanedPath, r); route != nil {
		return route
	}

	for _, ro := range u.Routes {
		if ro.isMatch(cleanedPath, r) {
			return &ro
		}
	}

	return nil
}

func (u *upstream) findGeoProxyRoute(cleanedPath string, r *http.Request) *routeEntry {
	u.mu.RLock()
	defer u.mu.RUnlock()

	if u.geoProxyBackend.String() == "" {
		return nil
	}

	// Some routes are safe to serve from this GitLab instance
	for _, ro := range u.geoLocalRoutes {
		if ro.isMatch(cleanedPath, r) {
			return &ro
		}
	}

	if cleanedPath == "/-/cable" {
		return &u.geoProxyCableRoute
	}

	return &u.geoProxyRoute
}

func (u *upstream) pollGeoProxyAPI() {
	defer close(u.geoPollerDone)

	for {
		// Check enableGeoProxyFeature every time because `callGeoProxyApi()` can change its value.
		// This is can also be disabled through the GEO_SECONDARY_PROXY env var.
		if !u.enableGeoProxyFeature {
			break
		}

		u.callGeoProxyAPI()
		u.geoProxyPollSleep(geoProxyAPIPollingInterval)
	}
}

// Calls /api/v4/geo/proxy and sets up routes
func (u *upstream) callGeoProxyAPI() {
	geoProxyData, err := u.APIClient.GetGeoProxyData()
	if err != nil {
		// Unable to determine Geo Proxy URL. Fallback on cached value.
		return
	}

	if !geoProxyData.GeoEnabled {
		// When Geo is not enabled, we don't need to proxy, as it unnecessarily polls the
		// API, whereas a restart is necessary to enable Geo in the first place; at which
		// point we get fresh data from the API.
		u.enableGeoProxyFeature = false
		return
	}

	hasProxyDataChanged := false
	if u.geoProxyBackend.String() != geoProxyData.GeoProxyURL.String() {
		// URL changed
		hasProxyDataChanged = true
	}

	if u.geoProxyExtraData != geoProxyData.GeoProxyExtraData {
		// Signed data changed
		hasProxyDataChanged = true
	}

	if hasProxyDataChanged {
		u.updateGeoProxyFieldsFromData(geoProxyData)
	}
}

func (u *upstream) updateGeoProxyFieldsFromData(geoProxyData *apipkg.GeoProxyData) {
	u.mu.Lock()
	defer u.mu.Unlock()

	u.geoProxyBackend = geoProxyData.GeoProxyURL
	u.geoProxyExtraData = geoProxyData.GeoProxyExtraData

	if u.geoProxyBackend.String() == "" {
		return
	}

	geoProxyWorkhorseHeaders := map[string]string{
		"Gitlab-Workhorse-Geo-Proxy":            "1",
		"Gitlab-Workhorse-Geo-Proxy-Extra-Data": u.geoProxyExtraData,
	}
	geoProxyRoundTripper := roundtripper.NewBackendRoundTripper(u.geoProxyBackend, "", u.ProxyHeadersTimeout, u.DevelopmentMode)
	geoProxyUpstream := proxypkg.NewProxy(
		u.geoProxyBackend,
		u.Version,
		geoProxyRoundTripper,
		proxypkg.WithCustomHeaders(geoProxyWorkhorseHeaders),
		proxypkg.WithForcedTargetHostHeader(),
	)
	u.geoProxyCableRoute = u.wsRoute(newRoute(`^/-/cable\z`, "geo_action_cable", railsBackend), geoProxyUpstream)
	u.geoProxyRoute = u.route("", newRoute("", "proxy", geoPrimaryBackend), geoProxyUpstream, withGeoProxy())
}

func httpError(w http.ResponseWriter, r *http.Request, error string, code int) {
	if r.ProtoAtLeast(1, 1) {
		// Force client to disconnect if we render request error
		w.Header().Set("Connection", "close")
	}

	http.Error(w, error, code)
}

func fixRemoteAddr(r *http.Request) {
	// Unix domain sockets have a remote addr of @. This will make the
	// xff package lookup the X-Forwarded-For address if available.
	if r.RemoteAddr == "@" {
		r.RemoteAddr = "127.0.0.1:0"
	}
	r.RemoteAddr = xff.GetRemoteAddr(r)
}

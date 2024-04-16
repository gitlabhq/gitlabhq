package upstream

import (
	"net/http"
	"net/url"
	"regexp"

	"github.com/gorilla/websocket"
	"github.com/prometheus/client_golang/prometheus"

	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/tracing"

	apipkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/artifacts"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/builds"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/channel"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/dependencyproxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/git"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/imageresizer"
	proxypkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/queueing"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/sendfile"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/sendurl"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/staticpages"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload"
)

type matcherFunc func(*http.Request) bool

type routeEntry struct {
	method   string
	regex    *regexp.Regexp
	handler  http.Handler
	matchers []matcherFunc
}

type routeOptions struct {
	tracing         bool
	isGeoProxyRoute bool
	matchers        []matcherFunc
}

const (
	apiPattern           = `^/api/`
	gitProjectPattern    = `^/.+\.git/`
	geoGitProjectPattern = `^/[^-].+\.git/` // Prevent matching routes like /-/push_from_secondary
	projectPattern       = `^/([^/]+/){1,}[^/]+/`
	apiProjectPattern    = apiPattern + `v4/projects/[^/]+` // API: Projects can be encoded via group%2Fsubgroup%2Fproject
	apiGroupPattern      = apiPattern + `v4/groups/[^/]+`
	apiTopicPattern      = apiPattern + `v4/topics`
	snippetUploadPattern = `^/uploads/personal_snippet`
	userUploadPattern    = `^/uploads/user`
	importPattern        = `^/import/`
)

var (
	// For legacy reasons, user uploads are stored in public/uploads.  To
	// prevent anybody who knows/guesses the URL of a user-uploaded file
	// from downloading it we configure static.ServeExisting to treat files
	// under public/uploads/ as if they do not exist.
	staticExclude = []string{"/uploads/"}
)

func compileRegexp(regexpStr string) *regexp.Regexp {
	if len(regexpStr) == 0 {
		return nil
	}

	return regexp.MustCompile(regexpStr)
}

func withMatcher(f matcherFunc) func(*routeOptions) {
	return func(options *routeOptions) {
		options.matchers = append(options.matchers, f)
	}
}

func withoutTracing() func(*routeOptions) {
	return func(options *routeOptions) {
		options.tracing = false
	}
}

func withGeoProxy() func(*routeOptions) {
	return func(options *routeOptions) {
		options.isGeoProxyRoute = true
	}
}

func (u *upstream) observabilityMiddlewares(handler http.Handler, method string, regexpStr string, opts *routeOptions) http.Handler {
	handler = log.AccessLogger(
		handler,
		log.WithAccessLogger(u.accessLogger),
		log.WithExtraFields(func(r *http.Request) log.Fields {
			return log.Fields{
				"route": regexpStr, // This field matches the `route` label in Prometheus metrics
			}
		}),
	)

	handler = instrumentRoute(handler, method, regexpStr) // Add prometheus metrics

	if opts != nil && opts.isGeoProxyRoute {
		handler = instrumentGeoProxyRoute(handler, method, regexpStr) // Add Geo prometheus metrics
	}

	return handler
}

func (u *upstream) route(method, regexpStr string, handler http.Handler, opts ...func(*routeOptions)) routeEntry {
	// Instantiate a route with the defaults
	options := routeOptions{
		tracing: true,
	}

	for _, f := range opts {
		f(&options)
	}

	handler = u.observabilityMiddlewares(handler, method, regexpStr, &options)
	handler = denyWebsocket(handler) // Disallow websockets
	if options.tracing {
		// Add distributed tracing
		handler = tracing.Handler(handler, tracing.WithRouteIdentifier(regexpStr))
	}

	return routeEntry{
		method:   method,
		regex:    compileRegexp(regexpStr),
		handler:  handler,
		matchers: options.matchers,
	}
}

func (u *upstream) wsRoute(regexpStr string, handler http.Handler, matchers ...matcherFunc) routeEntry {
	method := "GET"
	handler = u.observabilityMiddlewares(handler, method, regexpStr, nil)

	return routeEntry{
		method:   method,
		regex:    compileRegexp(regexpStr),
		handler:  handler,
		matchers: append(matchers, websocket.IsWebSocketUpgrade),
	}
}

// Creates matcherFuncs for a particular content type.
func isContentType(contentType string) func(*http.Request) bool {
	return func(r *http.Request) bool {
		return helper.IsContentType(contentType, r.Header.Get("Content-Type"))
	}
}

func (ro *routeEntry) isMatch(cleanedPath string, req *http.Request) bool {
	if ro.method != "" && req.Method != ro.method {
		return false
	}

	if ro.regex != nil && !ro.regex.MatchString(cleanedPath) {
		return false
	}

	ok := true
	for _, matcher := range ro.matchers {
		ok = matcher(req)
		if !ok {
			break
		}
	}

	return ok
}

func buildProxy(backend *url.URL, version string, rt http.RoundTripper, cfg config.Config, dependencyProxyInjector *dependencyproxy.Injector) http.Handler {
	proxier := proxypkg.NewProxy(backend, version, rt)

	return senddata.SendData(
		sendfile.SendFile(apipkg.Block(proxier)),
		git.SendArchive,
		git.SendBlob,
		git.SendDiff,
		git.SendPatch,
		git.SendSnapshot,
		artifacts.SendEntry,
		sendurl.SendURL,
		imageresizer.NewResizer(cfg),
		dependencyProxyInjector,
	)
}

// Routing table
// We match against URI not containing the relativeUrlRoot:
// see upstream.ServeHTTP

func configureRoutes(u *upstream) {
	api := u.APIClient
	static := &staticpages.Static{DocumentRoot: u.DocumentRoot, Exclude: staticExclude}
	dependencyProxyInjector := dependencyproxy.NewInjector()
	proxy := buildProxy(u.Backend, u.Version, u.RoundTripper, u.Config, dependencyProxyInjector)
	cableProxy := proxypkg.NewProxy(u.CableBackend, u.Version, u.CableRoundTripper)

	assetsNotFoundHandler := NotFoundUnless(u.DevelopmentMode, proxy)
	if u.AltDocumentRoot != "" {
		altStatic := &staticpages.Static{DocumentRoot: u.AltDocumentRoot, Exclude: staticExclude}
		assetsNotFoundHandler = altStatic.ServeExisting(
			u.URLPrefix,
			staticpages.CacheExpireMax,
			NotFoundUnless(u.DevelopmentMode, proxy),
		)
	}

	signingTripper := secret.NewRoundTripper(u.RoundTripper, u.Version)
	signingProxy := buildProxy(u.Backend, u.Version, signingTripper, u.Config, dependencyProxyInjector)

	preparer := upload.NewObjectStoragePreparer(u.Config)
	requestBodyUploader := upload.RequestBody(api, signingProxy, preparer)
	mimeMultipartUploader := upload.Multipart(api, signingProxy, preparer, &u.Config)

	tempfileMultipartProxy := upload.FixedPreAuthMultipart(api, proxy, preparer, &u.Config)
	ciAPIProxyQueue := queueing.QueueRequests("ci_api_job_requests", tempfileMultipartProxy, u.APILimit, u.APIQueueLimit, u.APIQueueTimeout, prometheus.DefaultRegisterer)
	ciAPILongPolling := builds.RegisterHandler(ciAPIProxyQueue, u.watchKeyHandler, u.APICILongPollingDuration)

	dependencyProxyInjector.SetUploadHandler(requestBodyUploader)

	// Serve static files or forward the requests
	defaultUpstream := static.ServeExisting(
		u.URLPrefix,
		staticpages.CacheDisabled,
		static.DeployPage(static.ErrorPagesUnless(u.DevelopmentMode, staticpages.ErrorFormatHTML, tempfileMultipartProxy)),
	)
	probeUpstream := static.ErrorPagesUnless(u.DevelopmentMode, staticpages.ErrorFormatJSON, proxy)
	healthUpstream := static.ErrorPagesUnless(u.DevelopmentMode, staticpages.ErrorFormatText, proxy)

	u.Routes = []routeEntry{
		// Git Clone
		u.route("GET", gitProjectPattern+`info/refs\z`, git.GetInfoRefsHandler(api)),
		u.route("POST", gitProjectPattern+`git-upload-pack\z`, contentEncodingHandler(git.UploadPack(api)), withMatcher(isContentType("application/x-git-upload-pack-request"))),
		u.route("POST", gitProjectPattern+`git-receive-pack\z`, contentEncodingHandler(git.ReceivePack(api)), withMatcher(isContentType("application/x-git-receive-pack-request"))),
		u.route("PUT", gitProjectPattern+`gitlab-lfs/objects/([0-9a-f]{64})/([0-9]+)\z`, requestBodyUploader, withMatcher(isContentType("application/octet-stream"))),

		// CI Artifacts
		u.route("POST", apiPattern+`v4/jobs/[0-9]+/artifacts\z`, contentEncodingHandler(upload.Artifacts(api, signingProxy, preparer, &u.Config))),

		// ActionCable websocket
		u.wsRoute(`^/-/cable\z`, cableProxy),

		// Terminal websocket
		u.wsRoute(projectPattern+`-/environments/[0-9]+/terminal.ws\z`, channel.Handler(api)),
		u.wsRoute(projectPattern+`-/jobs/[0-9]+/terminal.ws\z`, channel.Handler(api)),

		// Proxy Job Services
		u.wsRoute(projectPattern+`-/jobs/[0-9]+/proxy.ws\z`, channel.Handler(api)),

		// Long poll and limit capacity given to jobs/request and builds/register.json
		u.route("", apiPattern+`v4/jobs/request\z`, ciAPILongPolling),

		// Not all API endpoints support encoded project IDs
		// (e.g. `group%2Fproject`), but for the sake of consistency we
		// use the apiProjectPattern regex throughout. API endpoints
		// that do not support this will return 400 regardless of
		// whether they are accelerated by Workhorse or not.  See
		// https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56731.

		// Maven Artifact Repository
		u.route("PUT", apiProjectPattern+`/packages/maven/`, requestBodyUploader),

		// Conan Artifact Repository
		u.route("PUT", apiPattern+`v4/packages/conan/`, requestBodyUploader),
		u.route("PUT", apiProjectPattern+`/packages/conan/`, requestBodyUploader),

		// Generic Packages Repository
		u.route("PUT", apiProjectPattern+`/packages/generic/`, requestBodyUploader),

		// Ml Model Packages Repository
		u.route("PUT", apiProjectPattern+`/packages/ml_models/`, requestBodyUploader),

		// NuGet Artifact Repository
		u.route("PUT", apiProjectPattern+`/packages/nuget/`, mimeMultipartUploader),

		// NuGet v2 Artifact Repository
		u.route("PUT", apiProjectPattern+`/packages/nuget/v2`, mimeMultipartUploader),

		// PyPI Artifact Repository
		u.route("POST", apiProjectPattern+`/packages/pypi`, mimeMultipartUploader),

		// Debian Artifact Repository
		u.route("PUT", apiProjectPattern+`/packages/debian/`, requestBodyUploader),

		// RPM Artifact Repository
		u.route("POST", apiProjectPattern+`/packages/rpm/`, requestBodyUploader),

		// Gem Artifact Repository
		u.route("POST", apiProjectPattern+`/packages/rubygems/`, requestBodyUploader),

		// Terraform Module Package Repository
		u.route("PUT", apiProjectPattern+`/packages/terraform/modules/`, requestBodyUploader),

		// Helm Artifact Repository
		u.route("POST", apiProjectPattern+`/packages/helm/api/[^/]+/charts\z`, mimeMultipartUploader),

		// We are porting API to disk acceleration
		// we need to declare each routes until we have fixed all the routes on the rails codebase.
		// Overall status can be seen at https://gitlab.com/groups/gitlab-org/-/epics/1802#current-status
		u.route("POST", apiProjectPattern+`/wikis/attachments\z`, tempfileMultipartProxy),
		u.route("POST", apiGroupPattern+`/wikis/attachments\z`, tempfileMultipartProxy),
		u.route("POST", apiPattern+`graphql\z`, tempfileMultipartProxy),
		u.route("POST", apiTopicPattern, tempfileMultipartProxy),
		u.route("PUT", apiTopicPattern, tempfileMultipartProxy),
		u.route("POST", apiPattern+`v4/groups/import`, mimeMultipartUploader),
		u.route("POST", apiPattern+`v4/projects/import`, mimeMultipartUploader),
		u.route("POST", apiPattern+`v4/projects/import-relation`, mimeMultipartUploader),

		// Project Import via UI upload acceleration
		u.route("POST", importPattern+`gitlab_project`, mimeMultipartUploader),
		// Group Import via UI upload acceleration
		u.route("POST", importPattern+`gitlab_group`, mimeMultipartUploader),

		// Issuable Metric image upload
		u.route("POST", apiProjectPattern+`/issues/[0-9]+/metric_images\z`, mimeMultipartUploader),

		// Alert Metric image upload
		u.route("POST", apiProjectPattern+`/alert_management_alerts/[0-9]+/metric_images\z`, mimeMultipartUploader),

		// Requirements Import via UI upload acceleration
		u.route("POST", projectPattern+`requirements_management/requirements/import_csv`, mimeMultipartUploader),

		// Work items Import via UI upload acceleration
		u.route("POST", projectPattern+`work_items/import_csv`, mimeMultipartUploader),

		// Uploads via API
		u.route("POST", apiProjectPattern+`/uploads\z`, mimeMultipartUploader),

		// Project Avatar
		u.route("POST", apiPattern+`v4/projects\z`, tempfileMultipartProxy),
		u.route("PUT", apiProjectPattern+`\z`, tempfileMultipartProxy),

		// Group Avatar
		u.route("POST", apiPattern+`v4/groups\z`, tempfileMultipartProxy),
		u.route("PUT", apiPattern+`v4/groups/[^/]+\z`, tempfileMultipartProxy),

		// User Avatar
		u.route("POST", apiPattern+`v4/users\z`, tempfileMultipartProxy),
		u.route("PUT", apiPattern+`v4/users/[0-9]+\z`, tempfileMultipartProxy),

		// Explicitly proxy API requests
		u.route("", apiPattern, proxy),

		// Serve assets
		u.route(
			"", `^/assets/`,
			static.ServeExisting(
				u.URLPrefix,
				staticpages.CacheExpireMax,
				assetsNotFoundHandler,
			),
			withoutTracing(), // Tracing on assets is very noisy
		),

		// Uploads
		u.route("POST", projectPattern+`uploads\z`, mimeMultipartUploader),
		u.route("POST", snippetUploadPattern, mimeMultipartUploader),
		u.route("POST", userUploadPattern, mimeMultipartUploader),

		// health checks don't intercept errors and go straight to rails
		// TODO: We should probably not return a HTML deploy page?
		//       https://gitlab.com/gitlab-org/gitlab/-/issues/336326
		u.route("", "^/-/(readiness|liveness)$", static.DeployPage(probeUpstream)),
		u.route("", "^/-/health$", static.DeployPage(healthUpstream)),

		// This route lets us filter out health checks from our metrics.
		u.route("", "^/-/", defaultUpstream),

		u.route("", "", defaultUpstream),
	}

	// Routes which should actually be served locally by a Geo Proxy. If none
	// matches, then then proxy the request.
	u.geoLocalRoutes = []routeEntry{
		// Git and LFS requests
		//
		// Note that Geo already redirects pushes, with special terminal output.
		// Note that excessive secondary lag can cause unexpected behavior since
		// pulls are performed against a different source of truth. Ideally, we'd
		// proxy/redirect pulls as well, when the secondary is not up-to-date.
		//
		u.route("GET", geoGitProjectPattern+`info/refs\z`, git.GetInfoRefsHandler(api)),
		u.route("POST", geoGitProjectPattern+`git-upload-pack\z`, contentEncodingHandler(git.UploadPack(api)), withMatcher(isContentType("application/x-git-upload-pack-request"))),
		u.route("GET", geoGitProjectPattern+`gitlab-lfs/objects/([0-9a-f]{64})\z`, defaultUpstream),
		u.route("POST", geoGitProjectPattern+`info/lfs/objects/batch\z`, defaultUpstream),

		// Serve health checks from this Geo secondary
		u.route("", "^/-/(readiness|liveness)$", static.DeployPage(probeUpstream)),
		u.route("", "^/-/health$", static.DeployPage(healthUpstream)),
		u.route("", "^/-/metrics$", defaultUpstream),

		// Authentication routes
		u.route("", "^/users/auth/geo/(sign_in|sign_out)$", defaultUpstream),
		u.route("", "^/oauth/geo/(auth|callback|logout)$", defaultUpstream),

		// Admin Area > Geo routes
		u.route("", "^/admin/geo/replication/projects", defaultUpstream),
		u.route("", "^/admin/geo/replication/designs", defaultUpstream),

		// Geo API routes
		u.route("", "^/api/v4/geo_replication", defaultUpstream),
		u.route("", "^/api/v4/geo/proxy_git_ssh", defaultUpstream),
		u.route("", "^/api/v4/geo/graphql", defaultUpstream),
		u.route("", "^/api/v4/geo_nodes/current/failures", defaultUpstream),
		u.route("", "^/api/v4/geo_sites/current/failures", defaultUpstream),

		// Internal API routes
		u.route("", "^/api/v4/internal", defaultUpstream),

		u.route(
			"", `^/assets/`,
			static.ServeExisting(
				u.URLPrefix,
				staticpages.CacheExpireMax,
				assetsNotFoundHandler,
			),
			withoutTracing(), // Tracing on assets is very noisy
		),

		// Don't define a catch-all route. If a route does not match, then we know
		// the request should be proxied.
	}
}

func denyWebsocket(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if websocket.IsWebSocketUpgrade(r) {
			httpError(w, r, "websocket upgrade not allowed", http.StatusBadRequest)
			return
		}

		next.ServeHTTP(w, r)
	})
}

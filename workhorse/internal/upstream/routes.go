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
	gobpkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/gob"
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

type routeBackend string

type routeMetadata struct {
	regexpStr string
	routeID   string
	backendID routeBackend
}

type routeOptions struct {
	tracing         bool
	isGeoProxyRoute bool
	matchers        []matcherFunc
	allowOrigins    *regexp.Regexp
}

const (
	apiPattern           = `^/api/`
	gitProjectPattern    = `^/.+\.git/`
	geoGitProjectPattern = `^/[^-].+\.git/` // Prevent matching routes like /-/push_from_secondary
	projectPattern       = `^/([^/]+/){1,}[^/]+/`
	groupPattern         = `^/groups/([^/]+/){0,}[^/]+/`
	apiProjectPattern    = apiPattern + `v4/projects/[^/]+` // API: Projects can be encoded via group%2Fsubgroup%2Fproject
	apiGroupPattern      = apiPattern + `v4/groups/[^/]+`
	apiTopicPattern      = apiPattern + `v4/topics`
	snippetUploadPattern = `^/uploads/personal_snippet`
	userUploadPattern    = `^/uploads/user`
	importPattern        = `^/import/`

	selfBackend       routeBackend = "self"
	railsBackend      routeBackend = "rails"
	gitalyBackend     routeBackend = "gitaly"
	geoPrimaryBackend routeBackend = "geo_primary_site"
)

var (
	// For legacy reasons, user uploads are stored in public/uploads.  To
	// prevent anybody who knows/guesses the URL of a user-uploaded file
	// from downloading it we configure static.ServeExisting to treat files
	// under public/uploads/ as if they do not exist.
	staticExclude = []string{"/uploads/"}
)

func newRoute(regexpStr, routeID string, backendID routeBackend) routeMetadata {
	return routeMetadata{regexpStr, routeID, backendID}
}

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

func withAllowOrigins(pattern string) func(*routeOptions) {
	return func(options *routeOptions) {
		options.allowOrigins = compileRegexp(pattern)
	}
}

func (u *upstream) observabilityMiddlewares(handler http.Handler, method string, metadata routeMetadata, opts *routeOptions) http.Handler {
	handler = log.AccessLogger(
		handler,
		log.WithAccessLogger(u.accessLogger),
		log.WithExtraFields(func(_ *http.Request) log.Fields {
			return log.Fields{
				"route":      metadata.regexpStr, // This field matches the `route` label in Prometheus metrics
				"route_id":   metadata.routeID,
				"backend_id": metadata.backendID,
			}
		}),
	)

	handler = instrumentRoute(handler, method, metadata) // Add prometheus metrics

	if opts != nil && opts.isGeoProxyRoute {
		handler = instrumentGeoProxyRoute(handler, method, metadata) // Add Geo prometheus metrics
	}

	return handler
}

func (u *upstream) route(method string, metadata routeMetadata, handler http.Handler, opts ...func(*routeOptions)) routeEntry {
	// Instantiate a route with the defaults
	options := routeOptions{
		tracing: true,
	}

	for _, f := range opts {
		f(&options)
	}

	handler = u.observabilityMiddlewares(handler, method, metadata, &options)
	handler = denyWebsocket(handler) // Disallow websockets
	if options.tracing {
		// Add distributed tracing
		handler = tracing.Handler(handler, tracing.WithRouteIdentifier(metadata.regexpStr))
	}
	if options.allowOrigins != nil {
		handler = corsMiddleware(handler, options.allowOrigins)
	}

	return routeEntry{
		method:   method,
		regex:    compileRegexp(metadata.regexpStr),
		handler:  handler,
		matchers: options.matchers,
	}
}

func (u *upstream) wsRoute(metadata routeMetadata, handler http.Handler, matchers ...matcherFunc) routeEntry {
	method := "GET"
	handler = u.observabilityMiddlewares(handler, method, metadata, nil)

	return routeEntry{
		method:   method,
		regex:    compileRegexp(metadata.regexpStr),
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

	gob := gobpkg.NewProxy(api, u.Version, u.ProxyHeadersTimeout, u.Config)

	u.Routes = []routeEntry{
		// Git Clone
		u.route("GET",
			newRoute(gitProjectPattern+`info/refs\z`, "git_info_refs", gitalyBackend),
			git.GetInfoRefsHandler(api)),
		u.route("POST",
			newRoute(gitProjectPattern+`git-upload-pack\z`, "git_upload_pack", gitalyBackend),
			contentEncodingHandler(git.UploadPack(api)), withMatcher(isContentType("application/x-git-upload-pack-request"))),
		u.route("POST",
			newRoute(gitProjectPattern+`git-receive-pack\z`, "git_receive_pack", gitalyBackend),
			contentEncodingHandler(git.ReceivePack(api)), withMatcher(isContentType("application/x-git-receive-pack-request"))),
		u.route("PUT",
			newRoute(gitProjectPattern+`gitlab-lfs/objects/([0-9a-f]{64})/([0-9]+)\z`, "git_lfs_objects", railsBackend),
			requestBodyUploader, withMatcher(isContentType("application/octet-stream"))),
		u.route("POST",
			newRoute(gitProjectPattern+`ssh-upload-pack\z`, "ssh_upload_pack", gitalyBackend),
			git.SSHUploadPack(api)),
		u.route("POST",
			newRoute(gitProjectPattern+`ssh-receive-pack\z`, "ssh_receive_pack", gitalyBackend),
			git.SSHReceivePack(api)),

		// CI Artifacts
		u.route("POST",
			newRoute(apiPattern+`v4/jobs/[0-9]+/artifacts\z`, "api_jobs_request", railsBackend),
			contentEncodingHandler(upload.Artifacts(api, signingProxy, preparer, &u.Config))),

		// ActionCable websocket
		u.wsRoute(newRoute(`^/-/cable\z`, "action_cable", railsBackend),
			cableProxy),

		// Terminal websocket
		u.wsRoute(
			newRoute(projectPattern+`-/environments/[0-9]+/terminal.ws\z`, "project_environments_terminal_ws", railsBackend),
			channel.Handler(api)),
		u.wsRoute(newRoute(projectPattern+`-/jobs/[0-9]+/terminal.ws\z`, "project_jobs_terminal_ws", railsBackend),
			channel.Handler(api)),

		// Proxy Job Services
		u.wsRoute(
			newRoute(projectPattern+`-/jobs/[0-9]+/proxy.ws\z`, "project_jobs_proxy_ws", railsBackend),
			channel.Handler(api)),

		// Long poll and limit capacity given to jobs/request and builds/register.json
		u.route("",
			newRoute(apiPattern+`v4/jobs/request\z`, "api_jobs_request", railsBackend), ciAPILongPolling),

		// Not all API endpoints support encoded project IDs
		// (e.g. `group%2Fproject`), but for the sake of consistency we
		// use the apiProjectPattern regex throughout. API endpoints
		// that do not support this will return 400 regardless of
		// whether they are accelerated by Workhorse or not.  See
		// https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56731.

		// Maven Artifact Repository
		u.route("PUT",
			newRoute(apiProjectPattern+`/packages/maven/`, "projects_api_packages_maven", railsBackend), requestBodyUploader),

		// Conan Artifact Repository
		u.route("PUT",
			newRoute(apiPattern+`v4/packages/conan/`, "api_packages_conan", railsBackend), requestBodyUploader),
		u.route("PUT",
			newRoute(apiProjectPattern+`/packages/conan/`, "project_api_packages_conan", railsBackend), requestBodyUploader),

		// Generic Packages Repository
		u.route("PUT",
			newRoute(apiProjectPattern+`/packages/generic/`, "api_projects_packages_generic", railsBackend), requestBodyUploader),

		// Ml Model Packages Repository
		u.route("PUT",
			newRoute(apiProjectPattern+`/packages/ml_models/`, "api_projects_packages_ml_models", railsBackend), requestBodyUploader),

		// NuGet Artifact Repository
		u.route("PUT",
			newRoute(apiProjectPattern+`/packages/nuget/`, "api_projects_packages_nuget", railsBackend), mimeMultipartUploader),

		// NuGet v2 Artifact Repository
		u.route("PUT",
			newRoute(apiProjectPattern+`/packages/nuget/v2`, "api_projects_packages_nuget_v2", railsBackend), mimeMultipartUploader),

		// PyPI Artifact Repository
		u.route("POST",
			newRoute(apiProjectPattern+`/packages/pypi`, "api_projects_packages_pypi", railsBackend), mimeMultipartUploader),

		// Debian Artifact Repository
		u.route("PUT",
			newRoute(apiProjectPattern+`/packages/debian/`, "api_projects_packages_debian", railsBackend), requestBodyUploader),

		// RPM Artifact Repository
		u.route("POST",
			newRoute(apiProjectPattern+`/packages/rpm/`, "api_projects_packages_rpm", railsBackend), requestBodyUploader),

		// Gem Artifact Repository
		u.route("POST",
			newRoute(apiProjectPattern+`/packages/rubygems/`, "api_projects_packages_rubygems", railsBackend), requestBodyUploader),

		// Terraform Module Package Repository
		u.route("PUT",
			newRoute(apiProjectPattern+`/packages/terraform/modules/`, "api_projects_packages_terraform", railsBackend), requestBodyUploader),

		// Helm Artifact Repository
		u.route("POST",
			newRoute(apiProjectPattern+`/packages/helm/api/[^/]+/charts\z`, "api_projects_packages_helm", railsBackend), mimeMultipartUploader),

		// We are porting API to disk acceleration
		// we need to declare each routes until we have fixed all the routes on the rails codebase.
		// Overall status can be seen at https://gitlab.com/groups/gitlab-org/-/epics/1802#current-status
		u.route("POST",
			newRoute(apiProjectPattern+`/wikis/attachments\z`, "api_projects_wikis_attachments", railsBackend), tempfileMultipartProxy),
		u.route("POST",
			newRoute(apiGroupPattern+`/wikis/attachments\z`, "api_groups_wikis_attachments", railsBackend), tempfileMultipartProxy),
		u.route("POST",
			newRoute(apiPattern+`graphql\z`, "api_graphql", railsBackend), tempfileMultipartProxy),
		u.route("POST",
			newRoute(apiTopicPattern, "api_topics", railsBackend), tempfileMultipartProxy),
		u.route("PUT",
			newRoute(apiTopicPattern, "api_topics", railsBackend), tempfileMultipartProxy),
		u.route("POST",
			newRoute(apiPattern+`v4/groups/import`, "api_groups_import", railsBackend), mimeMultipartUploader),
		u.route("POST",
			newRoute(apiPattern+`v4/projects/import`, "api_projects_import", railsBackend), mimeMultipartUploader),
		u.route("POST",
			newRoute(apiPattern+`v4/projects/import-relation`, "api_projects_import_relation", railsBackend), mimeMultipartUploader),
		u.route("POST",
			newRoute(groupPattern+`-/group_members/bulk_reassignment_file`, "group_placeholder_assignment", railsBackend), mimeMultipartUploader),
		// Project Import via UI upload acceleration
		u.route("POST",
			newRoute(importPattern+`gitlab_project`, "import_gitlab_project", railsBackend), mimeMultipartUploader),
		// Group Import via UI upload acceleration
		u.route("POST",
			newRoute(importPattern+`gitlab_group`, "import_gitlab_group", railsBackend), mimeMultipartUploader),

		// Issuable Metric image upload
		u.route("POST",
			newRoute(apiProjectPattern+`/issues/[0-9]+/metric_images\z`, "api_projects_issues_metric_images", railsBackend), mimeMultipartUploader),

		// Alert Metric image upload
		u.route("POST",
			newRoute(apiProjectPattern+`/alert_management_alerts/[0-9]+/metric_images\z`, "api_projects_alert_management_alerts_metric_images", railsBackend), mimeMultipartUploader),

		// Requirements Import via UI upload acceleration
		u.route("POST",
			newRoute(projectPattern+`requirements_management/requirements/import_csv`, "project_requirements_import_csv", railsBackend), mimeMultipartUploader),

		// Work items Import via UI upload acceleration
		u.route("POST",
			newRoute(projectPattern+`work_items/import_csv`, "project_work_items_import_csv", railsBackend), mimeMultipartUploader),

		// Uploads via API
		u.route("POST",
			newRoute(apiProjectPattern+`/uploads\z`, "api_projects_uploads", railsBackend), mimeMultipartUploader),

		// Project Avatar
		u.route("POST",
			newRoute(apiPattern+`v4/projects\z`, "api_projects", railsBackend), tempfileMultipartProxy),
		u.route("PUT",
			newRoute(apiProjectPattern+`\z`, "api_projects", railsBackend), tempfileMultipartProxy),

		// Group Avatar
		u.route("POST",
			newRoute(apiPattern+`v4/groups\z`, "api_groups", railsBackend), tempfileMultipartProxy),
		u.route("PUT",
			newRoute(apiPattern+`v4/groups/[^/]+\z`, "api_groups", railsBackend), tempfileMultipartProxy),

		// Organization Avatar
		u.route("POST",
			newRoute(apiPattern+`v4/organizations\z`, "api_organizations", railsBackend), tempfileMultipartProxy),
		u.route("PUT",
			newRoute(apiPattern+`v4/organizations/[0-9]+\z`, "api_organizations", railsBackend), tempfileMultipartProxy),

		// User Avatar
		u.route("PUT",
			newRoute(apiPattern+`v4/user/avatar\z`, "api_user_avatar", railsBackend), tempfileMultipartProxy),
		u.route("POST",
			newRoute(apiPattern+`v4/users\z`, "api_users", railsBackend), tempfileMultipartProxy),
		u.route("PUT",
			newRoute(apiPattern+`v4/users/[0-9]+\z`, "api_users", railsBackend), tempfileMultipartProxy),

		// GitLab Observability Backend (GOB). Write paths are versioned with v1 to align with
		// OpenTelemetry compatibility, where SDKs POST to /v1/traces, /v1/logs and /v1/metrics.
		u.route("POST", newRoute(apiProjectPattern+`/observability/v1/traces`, "api_observability_traces", railsBackend), gob.WithProjectAuth("/write/traces")),
		u.route("POST", newRoute(apiProjectPattern+`/observability/v1/logs`, "api_observability_logs", railsBackend), gob.WithProjectAuth("/write/logs")),
		u.route("POST", newRoute(apiProjectPattern+`/observability/v1/metrics`, "api_observability_metrics", railsBackend), gob.WithProjectAuth("/write/metrics")),

		u.route("GET", newRoute(apiProjectPattern+`/observability/v1/analytics`, "api_observability_analytics", railsBackend), gob.WithProjectAuth("/read/analytics")),
		u.route("GET", newRoute(apiProjectPattern+`/observability/v1/traces`, "api_observability_traces", railsBackend), gob.WithProjectAuth("/read/traces")),
		u.route("GET", newRoute(apiProjectPattern+`/observability/v1/logs`, "api_observability_logs", railsBackend), gob.WithProjectAuth("/read/logs")),
		u.route("GET", newRoute(apiProjectPattern+`/observability/v1/metrics`, "api_observability_metrics", railsBackend), gob.WithProjectAuth("/read/metrics")),
		u.route("GET", newRoute(apiProjectPattern+`/observability/v1/services`, "api_observability_services", railsBackend), gob.WithProjectAuth("/read/services")),

		// Explicitly proxy API requests
		u.route("",
			newRoute(apiPattern, "api", railsBackend), proxy),

		// Serve assets
		u.route(
			"",
			newRoute(`^/assets/`, "assets", railsBackend),
			static.ServeExisting(
				u.URLPrefix,
				staticpages.CacheExpireMax,
				assetsNotFoundHandler,
			),
			withoutTracing(), // Tracing on assets is very noisy
			withAllowOrigins("^https://.*\\.web-ide\\.gitlab-static\\.net$"),
		),

		// Uploads
		u.route("POST",
			newRoute(projectPattern+`uploads\z`, "project_uploads", railsBackend), mimeMultipartUploader),
		u.route("POST",
			newRoute(snippetUploadPattern, "personal_snippet_uploads", railsBackend), mimeMultipartUploader),
		u.route("POST",
			newRoute(userUploadPattern, "user_uploads", railsBackend), mimeMultipartUploader),

		// health checks don't intercept errors and go straight to rails
		// TODO: We should probably not return a HTML deploy page?
		//       https://gitlab.com/gitlab-org/gitlab/-/issues/336326
		u.route("",
			newRoute("^/-/(readiness|liveness)$", "liveness", selfBackend), static.DeployPage(probeUpstream)),
		u.route("",
			newRoute("^/-/health$", "health", selfBackend), static.DeployPage(healthUpstream)),

		// This route lets us filter out health checks from our metrics.
		u.route("",
			newRoute("^/-/", "dash", railsBackend), defaultUpstream),

		u.route("",
			newRoute("", "default", railsBackend), defaultUpstream),
	}

	// Routes which should actually be served locally by a Geo Proxy. If none
	// matches, then then proxy the request.
	u.geoLocalRoutes = []routeEntry{
		// Git and LFS requests
		//
		// Geo already redirects pushes, with special terminal output.
		// Excessive secondary lag can cause unexpected behavior since
		// pulls are performed against a different source of truth. Ideally, we'd
		// proxy/redirect pulls as well, when the secondary is not up-to-date.
		//
		u.route("GET",
			newRoute(geoGitProjectPattern+`info/refs\z`, "geo_git_info_refs", "gitaly"), git.GetInfoRefsHandler(api)),
		u.route("POST",
			newRoute(geoGitProjectPattern+`git-upload-pack\z`, "geo_git_upload_pack", "gitaly"), contentEncodingHandler(git.UploadPack(api)), withMatcher(isContentType("application/x-git-upload-pack-request"))),
		u.route("GET",
			newRoute(geoGitProjectPattern+`gitlab-lfs/objects/([0-9a-f]{64})\z`, "geo_git_lfs_objects", railsBackend), defaultUpstream),
		u.route("POST",
			newRoute(geoGitProjectPattern+`info/lfs/objects/batch\z`, "geo_git_lfs_info_objects_batch", railsBackend), defaultUpstream),

		// Serve health checks from this Geo secondary
		u.route("",
			newRoute("^/-/(readiness|liveness)$", "geo_liveness", selfBackend), static.DeployPage(probeUpstream)),
		u.route("",
			newRoute("^/-/health$", "geo_health", selfBackend), static.DeployPage(healthUpstream)),
		u.route("",
			newRoute("^/-/metrics$", "geo_metrics", railsBackend), defaultUpstream),

		// Authentication routes
		u.route("",
			newRoute("^/users/auth/geo/(sign_in|sign_out)$", "users_auth_geo", railsBackend), defaultUpstream),
		u.route("",
			newRoute("^/oauth/geo/(auth|callback|logout)$", "oauth_geo", railsBackend), defaultUpstream),

		// Admin Area > Geo routes
		u.route("",
			newRoute("^/admin/geo/replication/projects", "admin_geo_replication_projects", railsBackend), defaultUpstream),
		u.route("",
			newRoute("^/admin/geo/replication/designs", "admin_geo_replication_designs", railsBackend), defaultUpstream),

		// Geo API routes
		u.route("",
			newRoute("^/api/v4/geo_replication", "api_geo_replication", railsBackend), defaultUpstream),
		u.route("",
			newRoute("^/api/v4/geo/proxy_git_ssh", "api_geo_proxy_git_ssh", railsBackend), defaultUpstream),
		u.route("",
			newRoute("^/api/v4/geo/graphql", "api_geo_graphql", railsBackend), defaultUpstream),
		u.route("",
			newRoute("^/api/v4/geo_nodes/current/failures", "api_geo_nodes_current_failures", railsBackend), defaultUpstream),
		u.route("",
			newRoute("^/api/v4/geo_sites/current/failures", "api_geo_sites_current_failures", railsBackend), defaultUpstream),

		// Internal API routes
		u.route("",
			newRoute("^/api/v4/internal", "api_internal", railsBackend), defaultUpstream),

		u.route(
			"",
			newRoute(`^/assets/`, "assets", railsBackend),
			static.ServeExisting(
				u.URLPrefix,
				staticpages.CacheExpireMax,
				assetsNotFoundHandler,
			),
			withoutTracing(), // Tracing on assets is very noisy
			withAllowOrigins("^https://.*\\.web-ide\\.gitlab-static\\.net$"),
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

func corsMiddleware(next http.Handler, allowOriginRegex *regexp.Regexp) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestOrigin := r.Header.Get("Origin")
		hasOriginMatch := allowOriginRegex.MatchString(requestOrigin)
		hasMethodMatch := r.Method == "GET" || r.Method == "HEAD" || r.Method == "OPTIONS"

		if hasOriginMatch && hasMethodMatch {
			w.Header().Set("Access-Control-Allow-Origin", requestOrigin)
			// why: `Vary: Origin` is needed because allowable origin is variable
			//      https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS#the_http_response_headers
			w.Header().Set("Vary", "Origin")
		}

		next.ServeHTTP(w, r)
	})
}

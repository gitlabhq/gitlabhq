package upstream

import (
	"net/http"
	"net/url"
	"path"
	"regexp"

	"github.com/gorilla/websocket"

	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/tracing"

	apipkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/artifacts"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/builds"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/channel"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/git"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/imageresizer"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/lfs"
	proxypkg "gitlab.com/gitlab-org/gitlab/workhorse/internal/proxy"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/queueing"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
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
	tracing  bool
	matchers []matcherFunc
}

type uploadPreparers struct {
	artifacts upload.Preparer
	lfs       upload.Preparer
	packages  upload.Preparer
	uploads   upload.Preparer
}

const (
	apiPattern           = `^/api/`
	ciAPIPattern         = `^/ci/api/`
	gitProjectPattern    = `^/.+\.git/`
	projectPattern       = `^/([^/]+/){1,}[^/]+/`
	apiProjectPattern    = apiPattern + `v4/projects/[^/]+/` // API: Projects can be encoded via group%2Fsubgroup%2Fproject
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

func (u *upstream) observabilityMiddlewares(handler http.Handler, method string, regexpStr string) http.Handler {
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

	handler = u.observabilityMiddlewares(handler, method, regexpStr)
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
	handler = u.observabilityMiddlewares(handler, method, regexpStr)

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

func buildProxy(backend *url.URL, version string, rt http.RoundTripper, cfg config.Config) http.Handler {
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
	)
}

// Routing table
// We match against URI not containing the relativeUrlRoot:
// see upstream.ServeHTTP

func configureRoutes(u *upstream) {
	api := u.APIClient
	static := &staticpages.Static{DocumentRoot: u.DocumentRoot, Exclude: staticExclude}
	proxy := buildProxy(u.Backend, u.Version, u.RoundTripper, u.Config)
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
	signingProxy := buildProxy(u.Backend, u.Version, signingTripper, u.Config)

	preparers := createUploadPreparers(u.Config)
	uploadPath := path.Join(u.DocumentRoot, "uploads/tmp")
	uploadAccelerateProxy := upload.Accelerate(&upload.SkipRailsAuthorizer{TempPath: uploadPath}, proxy, preparers.uploads)
	ciAPIProxyQueue := queueing.QueueRequests("ci_api_job_requests", uploadAccelerateProxy, u.APILimit, u.APIQueueLimit, u.APIQueueTimeout)
	ciAPILongPolling := builds.RegisterHandler(ciAPIProxyQueue, redis.WatchKey, u.APICILongPollingDuration)

	// Serve static files or forward the requests
	defaultUpstream := static.ServeExisting(
		u.URLPrefix,
		staticpages.CacheDisabled,
		static.DeployPage(static.ErrorPagesUnless(u.DevelopmentMode, staticpages.ErrorFormatHTML, uploadAccelerateProxy)),
	)
	probeUpstream := static.ErrorPagesUnless(u.DevelopmentMode, staticpages.ErrorFormatJSON, proxy)
	healthUpstream := static.ErrorPagesUnless(u.DevelopmentMode, staticpages.ErrorFormatText, proxy)

	u.Routes = []routeEntry{
		// Git Clone
		u.route("GET", gitProjectPattern+`info/refs\z`, git.GetInfoRefsHandler(api)),
		u.route("POST", gitProjectPattern+`git-upload-pack\z`, contentEncodingHandler(git.UploadPack(api)), withMatcher(isContentType("application/x-git-upload-pack-request"))),
		u.route("POST", gitProjectPattern+`git-receive-pack\z`, contentEncodingHandler(git.ReceivePack(api)), withMatcher(isContentType("application/x-git-receive-pack-request"))),
		u.route("PUT", gitProjectPattern+`gitlab-lfs/objects/([0-9a-f]{64})/([0-9]+)\z`, lfs.PutStore(api, signingProxy, preparers.lfs), withMatcher(isContentType("application/octet-stream"))),

		// CI Artifacts
		u.route("POST", apiPattern+`v4/jobs/[0-9]+/artifacts\z`, contentEncodingHandler(artifacts.UploadArtifacts(api, signingProxy, preparers.artifacts))),
		u.route("POST", ciAPIPattern+`v1/builds/[0-9]+/artifacts\z`, contentEncodingHandler(artifacts.UploadArtifacts(api, signingProxy, preparers.artifacts))),

		// ActionCable websocket
		u.wsRoute(`^/-/cable\z`, cableProxy),

		// Terminal websocket
		u.wsRoute(projectPattern+`-/environments/[0-9]+/terminal.ws\z`, channel.Handler(api)),
		u.wsRoute(projectPattern+`-/jobs/[0-9]+/terminal.ws\z`, channel.Handler(api)),

		// Proxy Job Services
		u.wsRoute(projectPattern+`-/jobs/[0-9]+/proxy.ws\z`, channel.Handler(api)),

		// Long poll and limit capacity given to jobs/request and builds/register.json
		u.route("", apiPattern+`v4/jobs/request\z`, ciAPILongPolling),
		u.route("", ciAPIPattern+`v1/builds/register.json\z`, ciAPILongPolling),

		// Not all API endpoints support encoded project IDs
		// (e.g. `group%2Fproject`), but for the sake of consistency we
		// use the apiProjectPattern regex throughout. API endpoints
		// that do not support this will return 400 regardless of
		// whether they are accelerated by Workhorse or not.  See
		// https://gitlab.com/gitlab-org/gitlab/-/merge_requests/56731.

		// Maven Artifact Repository
		u.route("PUT", apiProjectPattern+`packages/maven/`, upload.BodyUploader(api, signingProxy, preparers.packages)),

		// Conan Artifact Repository
		u.route("PUT", apiPattern+`v4/packages/conan/`, upload.BodyUploader(api, signingProxy, preparers.packages)),
		u.route("PUT", apiProjectPattern+`packages/conan/`, upload.BodyUploader(api, signingProxy, preparers.packages)),

		// Generic Packages Repository
		u.route("PUT", apiProjectPattern+`packages/generic/`, upload.BodyUploader(api, signingProxy, preparers.packages)),

		// NuGet Artifact Repository
		u.route("PUT", apiProjectPattern+`packages/nuget/`, upload.Accelerate(api, signingProxy, preparers.packages)),

		// PyPI Artifact Repository
		u.route("POST", apiProjectPattern+`packages/pypi`, upload.Accelerate(api, signingProxy, preparers.packages)),

		// Debian Artifact Repository
		u.route("PUT", apiProjectPattern+`packages/debian/`, upload.BodyUploader(api, signingProxy, preparers.packages)),

		// Gem Artifact Repository
		u.route("POST", apiProjectPattern+`packages/rubygems/`, upload.BodyUploader(api, signingProxy, preparers.packages)),

		// Terraform Module Package Repository
		u.route("PUT", apiProjectPattern+`packages/terraform/modules/`, upload.BodyUploader(api, signingProxy, preparers.packages)),

		// Helm Artifact Repository
		u.route("POST", apiProjectPattern+`packages/helm/api/[^/]+/charts\z`, upload.Accelerate(api, signingProxy, preparers.packages)),

		// We are porting API to disk acceleration
		// we need to declare each routes until we have fixed all the routes on the rails codebase.
		// Overall status can be seen at https://gitlab.com/groups/gitlab-org/-/epics/1802#current-status
		u.route("POST", apiProjectPattern+`wikis/attachments\z`, uploadAccelerateProxy),
		u.route("POST", apiPattern+`graphql\z`, uploadAccelerateProxy),
		u.route("POST", apiPattern+`v4/groups/import`, upload.Accelerate(api, signingProxy, preparers.uploads)),
		u.route("POST", apiPattern+`v4/projects/import`, upload.Accelerate(api, signingProxy, preparers.uploads)),

		// Project Import via UI upload acceleration
		u.route("POST", importPattern+`gitlab_project`, upload.Accelerate(api, signingProxy, preparers.uploads)),
		// Group Import via UI upload acceleration
		u.route("POST", importPattern+`gitlab_group`, upload.Accelerate(api, signingProxy, preparers.uploads)),

		// Metric image upload
		u.route("POST", apiProjectPattern+`issues/[0-9]+/metric_images\z`, upload.Accelerate(api, signingProxy, preparers.uploads)),

		// Requirements Import via UI upload acceleration
		u.route("POST", projectPattern+`requirements_management/requirements/import_csv`, upload.Accelerate(api, signingProxy, preparers.uploads)),

		// Uploads via API
		u.route("POST", apiProjectPattern+`uploads\z`, upload.Accelerate(api, signingProxy, preparers.uploads)),

		// Explicitly proxy API requests
		u.route("", apiPattern, proxy),
		u.route("", ciAPIPattern, proxy),

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
		u.route("POST", projectPattern+`uploads\z`, upload.Accelerate(api, signingProxy, preparers.uploads)),
		u.route("POST", snippetUploadPattern, upload.Accelerate(api, signingProxy, preparers.uploads)),
		u.route("POST", userUploadPattern, upload.Accelerate(api, signingProxy, preparers.uploads)),

		// health checks don't intercept errors and go straight to rails
		// TODO: We should probably not return a HTML deploy page?
		//       https://gitlab.com/gitlab-org/gitlab/-/issues/336326
		u.route("", "^/-/(readiness|liveness)$", static.DeployPage(probeUpstream)),
		u.route("", "^/-/health$", static.DeployPage(healthUpstream)),

		// This route lets us filter out health checks from our metrics.
		u.route("", "^/-/", defaultUpstream),

		u.route("", "", defaultUpstream),
	}
}

func createUploadPreparers(cfg config.Config) uploadPreparers {
	defaultPreparer := upload.NewObjectStoragePreparer(cfg)

	return uploadPreparers{
		artifacts: defaultPreparer,
		lfs:       lfs.NewLfsUploadPreparer(cfg, defaultPreparer),
		packages:  defaultPreparer,
		uploads:   defaultPreparer,
	}
}

func denyWebsocket(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if websocket.IsWebSocketUpgrade(r) {
			helper.HTTPError(w, r, "websocket upgrade not allowed", http.StatusBadRequest)
			return
		}

		next.ServeHTTP(w, r)
	})
}

// Package api provides functionalities for interacting with the API.
package api

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/textproto"
	"net/url"
	"strconv"
	"strings"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
)

const (
	// ResponseContentType for API responses, to catch routing / programming mistakes
	ResponseContentType = "application/vnd.gitlab-workhorse+json"

	failureResponseLimit = 32768

	geoProxyEndpointPath = "/api/v4/geo/proxy"
)

var errResponseLimit = fmt.Errorf("response body exceeded maximum buffer size (%d bytes)", failureResponseLimit)

// API represents a client for interacting with an external API.
type API struct {
	Client  *http.Client
	URL     *url.URL
	Version string
}

// PreAuthorizeFixedPathError represents an error returned when authorization fails due to fixed path.
type PreAuthorizeFixedPathError struct {
	StatusCode int
	Status     string
}

func (p *PreAuthorizeFixedPathError) Error() string {
	return fmt.Sprintf("no api response: status %d", p.StatusCode)
}

var (
	requestsCounter = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_internal_api_requests",
			Help: "How many internal API requests have been completed by gitlab-workhorse, partitioned by status code and HTTP method.",
		},
		[]string{"code", "method"},
	)
	bytesTotal = promauto.NewCounter(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_internal_api_failure_response_bytes",
			Help: "How many bytes have been returned by upstream GitLab in API failure/rejection response bodies.",
		},
	)
)

// NewAPI creates a new API client with the given URL, version, and round tripper.
func NewAPI(myURL *url.URL, version string, roundTripper http.RoundTripper) *API {
	return &API{
		Client:  &http.Client{Transport: roundTripper},
		URL:     myURL,
		Version: version,
	}
}

// GeoProxyEndpointResponse represents the response structure for geo-proxy endpoint data.
type GeoProxyEndpointResponse struct {
	GeoProxyURL       string `json:"geo_proxy_url"`
	GeoProxyExtraData string `json:"geo_proxy_extra_data"`
	GeoEnabled        bool   `json:"geo_enabled"`
}

// GeoProxyData represents data url, extra data and enabled or not.
type GeoProxyData struct {
	GeoProxyURL       *url.URL
	GeoProxyExtraData string
	GeoEnabled        bool
}

// HandleFunc defines the signature of functions used to handle HTTP requests.
type HandleFunc func(http.ResponseWriter, *http.Request, *Response)

// MultipartUploadParams represents parameters for a multipart upload operation.
type MultipartUploadParams struct {
	// PartSize is the exact size of each uploaded part. Only the last one can be smaller
	PartSize int64
	// PartURLs contains the presigned URLs for each part
	PartURLs []string
	// CompleteURL is a presigned URL for CompleteMulipartUpload
	CompleteURL string
	// AbortURL is a presigned URL for AbortMultipartUpload
	AbortURL string
}

// ObjectStorageParams represents parameters for configuring object storage.
type ObjectStorageParams struct {
	Provider      string
	S3Config      config.S3Config
	GoCloudConfig config.GoCloudConfig
}

// RemoteObject represents URLs for getting, deleting and storing objects in an object storage service.
type RemoteObject struct {
	// GetURL is an S3 GetObject URL
	GetURL string
	// DeleteURL is a presigned S3 RemoveObject URL
	DeleteURL string
	// Whether Workhorse needs to delete the temporary object or not.
	SkipDelete bool
	// StoreURL is the temporary presigned S3 PutObject URL to which upload the first found file
	StoreURL string
	// Boolean to indicate whether to use headers included in PutHeaders
	CustomPutHeaders bool
	// PutHeaders are HTTP headers (e.g. Content-Type) to be sent with StoreURL
	PutHeaders map[string]string
	// Whether to ignore Rails pre-signed URLs and have Workhorse directly access object storage provider
	UseWorkhorseClient bool
	// Remote, temporary object name where Rails will move to the final destination
	RemoteTempObjectID string
	// ID is a unique identifier of object storage upload
	ID string
	// Timeout is a number that represents timeout in seconds for sending data to StoreURL
	Timeout float32
	// MultipartUpload contains presigned URLs for S3 MultipartUpload
	MultipartUpload *MultipartUploadParams
	// Object storage config for Workhorse client
	ObjectStorage *ObjectStorageParams
}

// Response represents a structure containing various GitLab-related environment variables.
type Response struct {
	// GL_ID is an environment variable used by gitlab-shell hooks during 'git
	// push' and 'git pull'
	GL_ID string // nolint:stylecheck,revive // used as env variable

	// GL_USERNAME holds gitlab username of the user who is taking the action causing hooks to be invoked
	GL_USERNAME string // nolint:stylecheck,revive // used as env variable

	// GL_REPOSITORY is an environment variable used by gitlab-shell hooks during
	// 'git push' and 'git pull'
	GL_REPOSITORY string // nolint:stylecheck,revive // used as env variable

	// GitConfigOptions holds the custom options that we want to pass to the git command
	GitConfigOptions []string
	// StoreLFSPath is provided by the GitLab Rails application to mark where the tmp file should be placed.
	// This field is deprecated. GitLab will use TempPath instead
	StoreLFSPath string
	// LFS object id
	LfsOid string
	// LFS object size
	LfsSize int64
	// TmpPath is the path where we should store temporary files
	// This is set by authorization middleware
	TempPath string
	// RemoteObject is provided by the GitLab Rails application
	// and defines a way to store object on remote storage
	RemoteObject RemoteObject
	// Archive is the path where the artifacts archive is stored
	Archive string `json:"archive"`
	// Entry is a filename inside the archive point to file that needs to be extracted
	Entry string `json:"entry"`
	// Used to communicate channel session details
	Channel *ChannelSettings
	// GitalyServer specifies an address and authentication token for a gitaly server we should connect to.
	GitalyServer GitalyServer
	// Repository object for making gRPC requests to Gitaly.
	Repository gitalypb.Repository
	// For git-http, does the requestor have the right to view all refs?
	ShowAllRefs bool
	// Detects whether an artifact is used for code intelligence
	ProcessLsif bool
	// The maximum accepted size in bytes of the upload
	MaximumSize int64
	// A list of permitted hash functions. If empty, then all available are permitted.
	UploadHashFunctions []string
	// NeedAudit indicates whether git events should be audited to rails.
	NeedAudit bool `json:"NeedAudit"`
	// Gob contains settings for the GitLab Observability Backend (GOB).
	Gob GOBSettings `json:"gob"`
}

// GitalyServer represents configuration parameters for a Gitaly server,
// including its address, access token, and additional call metadata.
type GitalyServer struct {
	Address      string            `json:"address"`
	Token        string            `json:"token"`
	CallMetadata map[string]string `json:"call_metadata"`
}

// singleJoiningSlash is taken from reverseproxy.go:singleJoiningSlash
func singleJoiningSlash(a, b string) string {
	aslash := strings.HasSuffix(a, "/")
	bslash := strings.HasPrefix(b, "/")
	switch {
	case aslash && bslash:
		return a + b[1:]
	case !aslash && !bslash:
		return a + "/" + b
	}
	return a + b
}

// joinURLPath is taken from reverseproxy.go:joinURLPath
func joinURLPath(a *url.URL, b string) (path string, rawpath string) {
	// Avoid adding a trailing slash if the suffix is empty
	if b == "" {
		return a.Path, a.RawPath
	} else if a.RawPath == "" {
		return singleJoiningSlash(a.Path, b), ""
	}

	// Same as singleJoiningSlash, but uses EscapedPath to determine
	// whether a slash should be added
	apath := a.EscapedPath()
	bpath := b

	aslash := strings.HasSuffix(apath, "/")
	bslash := strings.HasPrefix(bpath, "/")

	switch {
	case aslash && bslash:
		return a.Path + bpath[1:], apath + bpath[1:]
	case !aslash && !bslash:
		return a.Path + "/" + bpath, apath + "/" + bpath
	}
	return a.Path + bpath, apath + bpath
}

// rebaseUrl is taken from reverseproxy.go:NewSingleHostReverseProxy
func rebaseURL(url *url.URL, onto *url.URL, suffix string) *url.URL {
	newURL := *url
	newURL.Scheme = onto.Scheme
	newURL.Host = onto.Host
	newURL.Path, newURL.RawPath = joinURLPath(url, suffix)

	if onto.RawQuery == "" || newURL.RawQuery == "" {
		newURL.RawQuery = onto.RawQuery + newURL.RawQuery
	} else {
		newURL.RawQuery = onto.RawQuery + "&" + newURL.RawQuery
	}
	return &newURL
}

func (api *API) newRequest(r *http.Request, suffix string) *http.Request {
	authReq := &http.Request{
		Method: r.Method,
		URL:    rebaseURL(r.URL, api.URL, suffix),
		Header: r.Header.Clone(),
	}

	authReq = authReq.WithContext(r.Context())

	removeConnectionHeaders(authReq.Header)

	// Clean some headers when issuing a new request without body
	authReq.Header.Del("Content-Type")
	authReq.Header.Del("Content-Encoding")
	authReq.Header.Del("Content-Length")
	authReq.Header.Del("Content-Disposition")
	authReq.Header.Del("Accept-Encoding")

	// Hop-by-hop headers. These are removed when sent to the backend.
	// http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html
	authReq.Header.Del("Transfer-Encoding")
	authReq.Header.Del("Connection")
	authReq.Header.Del("Keep-Alive")
	authReq.Header.Del("Proxy-Authenticate")
	authReq.Header.Del("Proxy-Authorization")
	authReq.Header.Del("Te")
	// "Trailer", not "Trailers" as per rfc2616; See errata https://www.rfc-editor.org/errata_search.php?eid=4522
	// See https://httpwg.org/http-core/draft-ietf-httpbis-semantics-latest.html#field.connection
	authReq.Header.Del("Trailer")
	authReq.Header.Del("Upgrade")

	// Also forward the Host header, which is excluded from the Header map by the http library.
	// This allows the Host header received by the backend to be consistent with other
	// requests not going through gitlab-workhorse.
	authReq.Host = r.Host

	return authReq
}

// GitAuditEventRequest represents a request for auditing a Git events.
type GitAuditEventRequest struct {
	Action        string                                  `json:"action"`
	Protocol      string                                  `json:"protocol"`
	Repo          string                                  `json:"gl_repository"`
	Username      string                                  `json:"username"`
	PackfileStats *gitalypb.PackfileNegotiationStatistics `json:"packfile_stats,omitempty"`
}

// SendGitAuditEvent sends a Git audit event using the API client.
func (api *API) SendGitAuditEvent(ctx context.Context, body GitAuditEventRequest) error {
	b, err := json.Marshal(body)
	if err != nil {
		return fmt.Errorf("failed to marshal GitAuditEventRequest: %w", err)
	}

	auditURL := *api.URL
	auditURL.Path = "/api/v4/internal/shellhorse/git_audit_event"
	auditReq, err := http.NewRequest(http.MethodPost, auditURL.String(), bytes.NewReader(b))
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}
	auditReq.Header.Set("User-Agent", "GitLab-Workhorse")
	auditReq.Header.Set("Content-Type", "application/json")
	auditReq = auditReq.WithContext(ctx)
	httpResponse, err := api.doRequestWithoutRedirects(auditReq)
	if err != nil {
		return fmt.Errorf("SendGitAuditEvent: do request: %v", err)
	}
	defer func() { _ = httpResponse.Body.Close() }()

	if httpResponse.StatusCode != http.StatusOK {
		return fmt.Errorf("SendGitAuditEvent: response status: %s", httpResponse.Status)
	}

	return nil
}

// PreAuthorize performs a pre-authorization check against the API for the given HTTP request
//
// If the returned *http.Response is not nil, the caller is responsible for closing its body
//
// Only upon successful authorization do we return a non-nil *Response
func (api *API) PreAuthorize(suffix string, r *http.Request) (_ *http.Response, _ *Response, err error) {
	authReq := api.newRequest(r, suffix)
	if err != nil {
		return nil, nil, fmt.Errorf("preAuthorizeHandler newUpstreamRequest: %v", err)
	}

	httpResponse, err := api.doRequestWithoutRedirects(authReq)
	if err != nil {
		return nil, nil, fmt.Errorf("preAuthorizeHandler: do request: %v", err)
	}
	defer func() {
		if err != nil {
			_ = httpResponse.Body.Close()
		}
	}()
	requestsCounter.WithLabelValues(strconv.Itoa(httpResponse.StatusCode), authReq.Method).Inc()

	// This may be a false positive, e.g. for .../info/refs, rather than a
	// failure, so pass the response back
	if httpResponse.StatusCode != http.StatusOK || !validResponseContentType(httpResponse) {
		return httpResponse, nil, nil
	}

	authResponse := &Response{}
	// The auth backend validated the client request and told us additional
	// request metadata. We must extract this information from the auth
	// response body.
	if err := json.NewDecoder(httpResponse.Body).Decode(authResponse); err != nil {
		return nil, nil, fmt.Errorf("preAuthorizeHandler: decode authorization response: %v", err)
	}

	return httpResponse, authResponse, nil
}

// PreAuthorizeFixedPath makes an internal Workhorse API call to a fixed
// path, using the HTTP headers of r.
func (api *API) PreAuthorizeFixedPath(r *http.Request, method string, path string) (*Response, error) {
	authReq, err := http.NewRequestWithContext(r.Context(), method, api.URL.String(), nil)
	if err != nil {
		return nil, fmt.Errorf("construct auth request: %w", err)
	}
	authReq.Header = r.Header.Clone()
	authReq.URL.RawQuery = r.URL.RawQuery

	failureResponse, apiResponse, err := api.PreAuthorize(path, authReq)
	if err != nil {
		return nil, fmt.Errorf("PreAuthorize: %w", err)
	}

	// We don't need the contents of failureResponse but we are responsible
	// for closing it. Part of the reason PreAuthorizeFixedPath exists is to
	// hide this awkwardness.
	if err = failureResponse.Body.Close(); err != nil {
		fmt.Printf("Error closing failureResponse body: %s", err)
	}

	if apiResponse == nil {
		return nil, &PreAuthorizeFixedPathError{StatusCode: failureResponse.StatusCode, Status: failureResponse.Status}
	}

	return apiResponse, nil
}

// PreAuthorizeHandler creates an HTTP handler that pre-authorizes requests.
func (api *API) PreAuthorizeHandler(next HandleFunc, suffix string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		httpResponse, authResponse, err := api.PreAuthorize(suffix, r)
		if httpResponse != nil {
			defer func() { _ = httpResponse.Body.Close() }()
		}

		if err != nil {
			fail.Request(w, r, err)
			return
		}

		// The response couldn't be interpreted as a valid auth response, so
		// pass it back (mostly) unmodified
		if httpResponse != nil && authResponse == nil {
			passResponseBack(httpResponse, w, r)
			return
		}

		defer func() { _ = httpResponse.Body.Close() }()

		copyAuthHeader(httpResponse, w)

		next(w, r, authResponse)
	})
}

func (api *API) doRequestWithoutRedirects(authReq *http.Request) (*http.Response, error) {
	signingTripper := secret.NewRoundTripper(api.Client.Transport, api.Version)

	return signingTripper.RoundTrip(authReq)
}

// removeConnectionHeaders removes hop-by-hop headers listed in the "Connection" header of h.
// See https://www.rfc-editor.org/rfc/rfc7230#section-6.1
func removeConnectionHeaders(h http.Header) {
	for _, f := range h["Connection"] {
		for _, sf := range strings.Split(f, ",") {
			if sf = textproto.TrimString(sf); sf != "" {
				h.Del(sf)
			}
		}
	}
}

func copyAuthHeader(httpResponse *http.Response, w http.ResponseWriter) {
	// Negotiate authentication (Kerberos) may need to return a WWW-Authenticate
	// header to the client even in case of success as per RFC4559.
	for k, v := range httpResponse.Header {
		// Case-insensitive comparison as per RFC7230
		if strings.EqualFold(k, "WWW-Authenticate") {
			w.Header()[k] = v
		}
	}
}

func passResponseBack(httpResponse *http.Response, w http.ResponseWriter, r *http.Request) {
	// NGINX response buffering is disabled on this path (with
	// X-Accel-Buffering: no) but we still want to free up the Puma thread
	// that generated httpResponse as fast as possible. To do this we buffer
	// the entire response body in memory before sending it on.
	responseBody, err := bufferResponse(httpResponse.Body)
	if err != nil {
		// A user can issue a git clone command against a URL that doesn't
		// get handled by the info refs endpoint, resulting in a full-fledged 404
		// response (i.e. like the one returned in a browser) that's gonna exceed
		// the response error limit, eventually making Workhorse returning a 500.
		// Here we intercept such 404s and just return the response code without a body.
		if errors.Is(err, errResponseLimit) && httpResponse.StatusCode == 404 {
			fail.Request(w, r, err, fail.WithStatus(httpResponse.StatusCode))
		} else {
			fail.Request(w, r, err)
		}
		return
	}

	if err = httpResponse.Body.Close(); err != nil {
		fmt.Printf("Error closing response body: %s", err)
	}
	bytesTotal.Add(float64(responseBody.Len()))

	for k, v := range httpResponse.Header {
		// Accommodate broken clients that do case-sensitive header lookup
		if k == "Www-Authenticate" {
			w.Header()["WWW-Authenticate"] = v
		} else {
			w.Header()[k] = v
		}
	}
	w.WriteHeader(httpResponse.StatusCode)
	if _, err := io.Copy(w, responseBody); err != nil {
		log.WithRequest(r).WithError(err).Error()
	}
}

func bufferResponse(r io.Reader) (*bytes.Buffer, error) {
	responseBody := &bytes.Buffer{}
	n, err := io.Copy(responseBody, io.LimitReader(r, failureResponseLimit))
	if err != nil {
		return nil, err
	}

	if n == failureResponseLimit {
		return nil, errResponseLimit
	}

	return responseBody, nil
}

func validResponseContentType(resp *http.Response) bool {
	return helper.IsContentType(ResponseContentType, resp.Header.Get("Content-Type"))
}

// GetGeoProxyData retrieves Geo proxy data from the API client.
func (api *API) GetGeoProxyData() (*GeoProxyData, error) {
	geoProxyAPIURL := *api.URL
	geoProxyAPIURL.Path, geoProxyAPIURL.RawPath = joinURLPath(api.URL, geoProxyEndpointPath)
	geoProxyAPIReq := &http.Request{
		Method: "GET",
		URL:    &geoProxyAPIURL,
		Header: make(http.Header),
	}

	httpResponse, err := api.doRequestWithoutRedirects(geoProxyAPIReq)
	if err != nil {
		return nil, fmt.Errorf("GetGeoProxyData: do request: %v", err)
	}
	defer func() { _ = httpResponse.Body.Close() }()

	if httpResponse.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("GetGeoProxyData: Received HTTP status code: %v", httpResponse.StatusCode)
	}

	response := &GeoProxyEndpointResponse{}
	if err = json.NewDecoder(httpResponse.Body).Decode(response); err != nil {
		return nil, fmt.Errorf("GetGeoProxyData: decode response: %v", err)
	}

	geoProxyURL, err := url.Parse(response.GeoProxyURL)
	if err != nil {
		return nil, fmt.Errorf("GetGeoProxyData: Could not parse Geo proxy URL: %v, err: %v", response.GeoProxyURL, err)
	}

	return &GeoProxyData{
		GeoProxyURL:       geoProxyURL,
		GeoProxyExtraData: response.GeoProxyExtraData,
		GeoEnabled:        response.GeoEnabled,
	}, nil
}

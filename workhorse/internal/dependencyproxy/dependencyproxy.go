// Package dependencyproxy provides functionality for handling dependency proxy operations
package dependencyproxy

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"sync"
	"time"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/transport"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload"
)

const dialTimeout = 10 * time.Second
const responseHeaderTimeout = 10 * time.Second
const uploadRequestGracePeriod = 60 * time.Second

var defaultTransportOptions = []transport.Option{
	transport.WithDialTimeout(dialTimeout),
	transport.WithResponseHeaderTimeout(responseHeaderTimeout),
	// Avoid automatic compression if the client did not request it because some object storage
	// providers use HTTP chunked encoding and omit Content-Length when gzip is in use.
	// The Docker client expects a Content-Length header when a HEAD request is made.
	transport.WithDisabledCompression(),
}

type cacheKey struct {
	ssrfFilter     bool
	allowLocalhost bool
	allowedURIs    string
}

var httpClients sync.Map

// Injector provides functionality for injecting dependencies
type Injector struct {
	senddata.Prefix
	uploadHandler upload.BodyUploadHandler
}

type entryParams struct {
	URL             string
	Headers         http.Header
	ResponseHeaders http.Header
	UploadConfig    uploadConfig
	SSRFFilter      bool
	AllowLocalhost  bool
	AllowedURIs     []string
}

type uploadConfig struct {
	Headers                  http.Header
	Method                   string
	URL                      string
	AuthorizedUploadResponse authorizeUploadResponse
}

type authorizeUploadResponse struct {
	TempPath            string
	RemoteObject        api.RemoteObject
	MaximumSize         int64
	UploadHashFunctions []string
}

func (u *uploadConfig) ExtractUploadAuthorizeFields() *api.Response {
	tempPath := u.AuthorizedUploadResponse.TempPath
	remoteID := u.AuthorizedUploadResponse.RemoteObject.RemoteTempObjectID

	if tempPath == "" && remoteID == "" {
		return nil
	}

	return &api.Response{
		TempPath:            tempPath,
		RemoteObject:        u.AuthorizedUploadResponse.RemoteObject,
		MaximumSize:         u.AuthorizedUploadResponse.MaximumSize,
		UploadHashFunctions: u.AuthorizedUploadResponse.UploadHashFunctions,
	}
}

type nullResponseWriter struct {
	header http.Header
	status int
}

func (nullResponseWriter) Write(p []byte) (int, error) {
	return len(p), nil
}

func (w *nullResponseWriter) Header() http.Header {
	return w.header
}

func (w *nullResponseWriter) WriteHeader(status int) {
	if w.status == 0 {
		w.status = status
	}
}

// NewInjector creates a new instance of Injector
func NewInjector() *Injector {
	return &Injector{Prefix: "send-dependency:"}
}

// SetUploadHandler sets the upload handler for the Injector
func (p *Injector) SetUploadHandler(uploadHandler upload.BodyUploadHandler) {
	p.uploadHandler = uploadHandler
}

// Inject performs the injection of dependencies
func (p *Injector) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	params, err := p.unpackParams(sendData)
	if err != nil {
		fail.Request(w, r, err)
		return
	}

	dependencyResponse, err := p.fetchURL(r.Context(), params)
	if err != nil {
		handleFetchError(w, r, err)
		return
	}
	defer func() { _ = dependencyResponse.Body.Close() }()

	if dependencyResponse.StatusCode >= 400 {
		handleErrorResponse(w, dependencyResponse)
		return
	}

	w.Header().Set("Content-Length", dependencyResponse.Header.Get("Content-Length"))

	teeReader := io.TeeReader(dependencyResponse.Body, w)
	// upload request context should follow the r context + a grace period
	ctx, cancel := context.WithCancel(context.WithoutCancel(r.Context()))
	defer cancel()

	stop := context.AfterFunc(r.Context(), func() {
		t := time.AfterFunc(uploadRequestGracePeriod, cancel) // call cancel function after 60 seconds

		context.AfterFunc(ctx, func() {
			if !t.Stop() { // if ctx is canceled and time still running, we stop the timer
				<-t.C // drain the channel because it's recommended in the docs: https://pkg.go.dev/time#Timer.Stop
			}
		})
	})
	defer stop()
	saveFileRequest, err := p.newUploadRequest(ctx, params, r, teeReader)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("dependency proxy: failed to create request: %w", err))
	}

	forwardHeaders(dependencyResponse.Header, saveFileRequest)

	p.forwardHeadersToResponse(w, dependencyResponse.Header, params.ResponseHeaders)

	// workhorse hijack overwrites the Content-Type header, but we need this header value
	saveFileRequest.Header.Set("Workhorse-Proxy-Content-Type", dependencyResponse.Header.Get("Content-Type"))
	saveFileRequest.ContentLength = dependencyResponse.ContentLength

	nrw := &nullResponseWriter{header: make(http.Header)}
	apiResponse := params.UploadConfig.ExtractUploadAuthorizeFields()
	if apiResponse != nil {
		p.uploadHandler.ServeHTTPWithAPIResponse(nrw, saveFileRequest, apiResponse)
	} else {
		p.uploadHandler.ServeHTTP(nrw, saveFileRequest)
	}

	if nrw.status != http.StatusOK {
		fields := log.Fields{"code": nrw.status}

		fail.Request(nrw, saveFileRequest, fmt.Errorf("dependency proxy: failed to upload file"), fail.WithFields(fields))
	}
}

func handleFetchError(w http.ResponseWriter, r *http.Request, err error) {
	status := http.StatusBadGateway
	if os.IsTimeout(err) {
		status = http.StatusGatewayTimeout
	}
	fail.Request(w, r, err, fail.WithStatus(status))
}

func handleErrorResponse(w http.ResponseWriter, dependencyResponse *http.Response) {
	w.WriteHeader(dependencyResponse.StatusCode)
	_, _ = io.Copy(w, dependencyResponse.Body) // swallow errors for investigation, see https://gitlab.com/gitlab-org/gitlab/-/issues/459952.
}

// forwardHeaders forwards headers from the dependency response to the saveFileRequest.
func forwardHeaders(dependencyHeader http.Header, saveFileRequest *http.Request) {
	for key, values := range dependencyHeader {
		saveFileRequest.Header.Del(key)
		for _, value := range values {
			saveFileRequest.Header.Add(key, value)
		}
	}
}
func (p *Injector) fetchURL(ctx context.Context, params *entryParams) (*http.Response, error) {
	r, err := http.NewRequestWithContext(ctx, "GET", params.URL, nil)
	if err != nil {
		return nil, fmt.Errorf("dependency proxy: failed to fetch dependency: %w", err)
	}
	r.Header = params.Headers

	return cachedClient(params).Do(r)
}

func (p *Injector) newUploadRequest(ctx context.Context, params *entryParams, originalRequest *http.Request, body io.Reader) (*http.Request, error) {
	method := p.uploadMethodFrom(params)
	uploadURL := p.uploadURLFrom(params, originalRequest)
	request, err := http.NewRequestWithContext(ctx, method, uploadURL, body)
	if err != nil {
		return nil, err
	}

	request.Header = originalRequest.Header.Clone()

	for key, values := range params.UploadConfig.Headers {
		request.Header.Del(key)
		for _, value := range values {
			request.Header.Add(key, value)
		}
	}

	return request, nil
}

func (p *Injector) forwardHeadersToResponse(w http.ResponseWriter, headers ...http.Header) {
	for _, h := range headers {
		for key, values := range h {
			w.Header().Del(key)
			for _, v := range values {
				w.Header().Add(key, v)
			}
		}
	}
}

func (p *Injector) unpackParams(sendData string) (*entryParams, error) {
	var params entryParams
	if err := p.Unpack(&params, sendData); err != nil {
		return nil, fmt.Errorf("dependency proxy: unpack sendData: %w", err)
	}

	if err := p.validateParams(&params); err != nil {
		return nil, fmt.Errorf("dependency proxy: invalid params: %w", err)
	}

	return &params, nil
}

func (p *Injector) validateParams(params *entryParams) error {
	var uploadMethod = params.UploadConfig.Method
	if uploadMethod != "" && uploadMethod != http.MethodPost && uploadMethod != http.MethodPut {
		return fmt.Errorf("invalid upload method %s", uploadMethod)
	}

	var uploadURL = params.UploadConfig.URL
	if uploadURL != "" {
		if _, err := url.ParseRequestURI(uploadURL); err != nil {
			return fmt.Errorf("invalid upload url %w", err)
		}
	}

	return nil
}

func (p *Injector) uploadMethodFrom(params *entryParams) string {
	if params.UploadConfig.Method != "" {
		return params.UploadConfig.Method
	}
	return http.MethodPost
}

func (p *Injector) uploadURLFrom(params *entryParams, originalRequest *http.Request) string {
	if params.UploadConfig.URL != "" {
		return params.UploadConfig.URL
	}

	return originalRequest.URL.String() + "/upload"
}

func cachedClient(params *entryParams) *http.Client {
	key := cacheKey{
		allowLocalhost: params.AllowLocalhost,
		ssrfFilter:     params.SSRFFilter,
		allowedURIs:    strings.Join(params.AllowedURIs, ","),
	}
	cachedClient, found := httpClients.Load(key)
	if found {
		return cachedClient.(*http.Client)
	}

	options := defaultTransportOptions

	if params.SSRFFilter {
		options = append(options, transport.WithSSRFFilter(params.AllowLocalhost, params.AllowedURIs))
	}

	client := &http.Client{
		Transport: transport.NewRestrictedTransport(options...),
	}

	httpClients.Store(key, client)

	return client
}

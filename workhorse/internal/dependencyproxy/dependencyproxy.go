// Package dependencyproxy provides functionality for handling dependency proxy operations
package dependencyproxy

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"time"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/transport"
)

const dialTimeout = 10 * time.Second
const responseHeaderTimeout = 10 * time.Second
const uploadRequestGracePeriod = 60 * time.Second

var httpTransport = transport.NewRestrictedTransport(transport.WithDialTimeout(dialTimeout), transport.WithResponseHeaderTimeout(responseHeaderTimeout))
var httpClient = &http.Client{
	Transport: httpTransport,
}

// Injector provides functionality for injecting dependencies
type Injector struct {
	senddata.Prefix
	uploadHandler http.Handler
}

type entryParams struct {
	URL          string
	Headers      http.Header
	UploadConfig uploadConfig
}

type uploadConfig struct {
	Headers http.Header
	Method  string
	URL     string
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
func (p *Injector) SetUploadHandler(uploadHandler http.Handler) {
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
		status := http.StatusBadGateway

		if os.IsTimeout(err) {
			status = http.StatusGatewayTimeout
		}

		fail.Request(w, r, err, fail.WithStatus(status))
		return
	}
	defer func() { _ = dependencyResponse.Body.Close() }()
	if dependencyResponse.StatusCode >= 400 {
		w.WriteHeader(dependencyResponse.StatusCode)
		// We swallow errors for now as we need to investigate further, see
		// https://gitlab.com/gitlab-org/gitlab/-/issues/459952.
		_, _ = io.Copy(w, dependencyResponse.Body)
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
			if !t.Stop() { // if ctx is cancelled and time still running, we stop the timer
				<-t.C // drain the channel because it's recommended in the docs: https://pkg.go.dev/time#Timer.Stop
			}
		})
	})
	defer stop()
	saveFileRequest, err := p.newUploadRequest(ctx, params, r, teeReader)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("dependency proxy: failed to create request: %w", err))
	}

	// forward headers from dependencyResponse to rails and client
	for key, values := range dependencyResponse.Header {
		saveFileRequest.Header.Del(key)
		w.Header().Del(key)
		for _, value := range values {
			saveFileRequest.Header.Add(key, value)
			w.Header().Add(key, value)
		}
	}

	// workhorse hijack overwrites the Content-Type header, but we need this header value
	saveFileRequest.Header.Set("Workhorse-Proxy-Content-Type", dependencyResponse.Header.Get("Content-Type"))
	saveFileRequest.ContentLength = dependencyResponse.ContentLength

	nrw := &nullResponseWriter{header: make(http.Header)}
	p.uploadHandler.ServeHTTP(nrw, saveFileRequest)

	if nrw.status != http.StatusOK {
		fields := log.Fields{"code": nrw.status}

		fail.Request(nrw, saveFileRequest, fmt.Errorf("dependency proxy: failed to upload file"), fail.WithFields(fields))
	}
}

func (p *Injector) fetchURL(ctx context.Context, params *entryParams) (*http.Response, error) {
	r, err := http.NewRequestWithContext(ctx, "GET", params.URL, nil)
	if err != nil {
		return nil, fmt.Errorf("dependency proxy: failed to fetch dependency: %w", err)
	}
	r.Header = params.Headers

	return httpClient.Do(r)
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

func (p *Injector) unpackParams(sendData string) (*entryParams, error) {
	var params entryParams
	if err := p.Unpack(&params, sendData); err != nil {
		return nil, fmt.Errorf("dependency proxy: unpack sendData: %w", err)
	}

	if err := p.validateParams(params); err != nil {
		return nil, fmt.Errorf("dependency proxy: invalid params: %w", err)
	}

	return &params, nil
}

func (p *Injector) validateParams(params entryParams) error {
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

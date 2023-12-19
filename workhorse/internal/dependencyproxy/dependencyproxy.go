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

var httpTransport = transport.NewRestrictedTransport(transport.WithDialTimeout(dialTimeout), transport.WithResponseHeaderTimeout(responseHeaderTimeout))
var httpClient = &http.Client{
	Transport: httpTransport,
}

type Injector struct {
	senddata.Prefix
	uploadHandler http.Handler
}

type entryParams struct {
	Url          string
	Headers      http.Header
	UploadConfig uploadConfig
}

type uploadConfig struct {
	Headers http.Header
	Method  string
	Url     string
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

func NewInjector() *Injector {
	return &Injector{Prefix: "send-dependency:"}
}

func (p *Injector) SetUploadHandler(uploadHandler http.Handler) {
	p.uploadHandler = uploadHandler
}

func (p *Injector) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	params, err := p.unpackParams(sendData)
	if err != nil {
		fail.Request(w, r, err)
		return
	}

	dependencyResponse, err := p.fetchUrl(r.Context(), params)
	if err != nil {
		status := http.StatusBadGateway

		if os.IsTimeout(err) {
			status = http.StatusGatewayTimeout
		}

		fail.Request(w, r, err, fail.WithStatus(status))
		return
	}
	defer dependencyResponse.Body.Close()
	if dependencyResponse.StatusCode >= 400 {
		w.WriteHeader(dependencyResponse.StatusCode)
		io.Copy(w, dependencyResponse.Body)
		return
	}

	w.Header().Set("Content-Length", dependencyResponse.Header.Get("Content-Length"))

	teeReader := io.TeeReader(dependencyResponse.Body, w)
	saveFileRequest, err := p.newUploadRequest(r.Context(), params, r, teeReader)
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

		fail.Request(nrw, r, fmt.Errorf("dependency proxy: failed to upload file"), fail.WithFields(fields))
	}
}

func (p *Injector) fetchUrl(ctx context.Context, params *entryParams) (*http.Response, error) {
	r, err := http.NewRequestWithContext(ctx, "GET", params.Url, nil)
	if err != nil {
		return nil, fmt.Errorf("dependency proxy: failed to fetch dependency: %w", err)
	}
	r.Header = params.Headers

	return httpClient.Do(r)
}

func (p *Injector) newUploadRequest(ctx context.Context, params *entryParams, originalRequest *http.Request, body io.Reader) (*http.Request, error) {
	method := p.uploadMethodFrom(params)
	uploadUrl := p.uploadUrlFrom(params, originalRequest)
	request, err := http.NewRequestWithContext(ctx, method, uploadUrl, body)
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

	var uploadUrl = params.UploadConfig.Url
	if uploadUrl != "" {
		if _, err := url.ParseRequestURI(uploadUrl); err != nil {
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

func (p *Injector) uploadUrlFrom(params *entryParams, originalRequest *http.Request) string {
	if params.UploadConfig.Url != "" {
		return params.UploadConfig.Url
	}

	return originalRequest.URL.String() + "/upload"
}

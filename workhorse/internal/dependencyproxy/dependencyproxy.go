package dependencyproxy

import (
	"context"
	"fmt"
	"io"
	"net"
	"net/http"
	"time"

	"gitlab.com/gitlab-org/labkit/correlation"
	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/tracing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
)

// httpTransport defines a http.Transport with values
// that are more restrictive than for http.DefaultTransport,
// they define shorter TLS Handshake, and more aggressive connection closing
// to prevent the connection hanging and reduce FD usage
var httpTransport = tracing.NewRoundTripper(correlation.NewInstrumentedRoundTripper(&http.Transport{
	Proxy: http.ProxyFromEnvironment,
	DialContext: (&net.Dialer{
		Timeout:   30 * time.Second,
		KeepAlive: 10 * time.Second,
	}).DialContext,
	MaxIdleConns:          2,
	IdleConnTimeout:       30 * time.Second,
	TLSHandshakeTimeout:   10 * time.Second,
	ExpectContinueTimeout: 10 * time.Second,
	ResponseHeaderTimeout: 30 * time.Second,
}))

var httpClient = &http.Client{
	Transport: httpTransport,
}

type Injector struct {
	senddata.Prefix
	uploadHandler http.Handler
}

type entryParams struct {
	Url    string
	Header http.Header
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
	dependencyResponse, err := p.fetchUrl(r.Context(), sendData)
	if err != nil {
		helper.Fail500(w, r, err)
		return
	}
	defer dependencyResponse.Body.Close()
	if dependencyResponse.StatusCode >= 400 {
		w.WriteHeader(dependencyResponse.StatusCode)
		io.Copy(w, dependencyResponse.Body)
		return
	}

	teeReader := io.TeeReader(dependencyResponse.Body, w)
	saveFileRequest, err := http.NewRequestWithContext(r.Context(), "POST", r.URL.String()+"/upload", teeReader)
	if err != nil {
		helper.Fail500(w, r, fmt.Errorf("dependency proxy: failed to create request: %w", err))
	}
	saveFileRequest.Header = helper.HeaderClone(r.Header)
	saveFileRequest.ContentLength = dependencyResponse.ContentLength

	w.Header().Del("Content-Length")

	nrw := &nullResponseWriter{header: make(http.Header)}
	p.uploadHandler.ServeHTTP(nrw, saveFileRequest)

	if nrw.status != http.StatusOK {
		fields := log.Fields{"code": nrw.status}

		helper.Fail500WithFields(nrw, r, fmt.Errorf("dependency proxy: failed to upload file"), fields)
	}
}

func (p *Injector) fetchUrl(ctx context.Context, sendData string) (*http.Response, error) {
	var params entryParams
	if err := p.Unpack(&params, sendData); err != nil {
		return nil, fmt.Errorf("dependency proxy: unpack sendData: %v", err)
	}

	r, err := http.NewRequestWithContext(ctx, "GET", params.Url, nil)
	if err != nil {
		return nil, fmt.Errorf("dependency proxy: failed to fetch dependency: %v", err)
	}
	r.Header = params.Header

	return httpClient.Do(r)
}

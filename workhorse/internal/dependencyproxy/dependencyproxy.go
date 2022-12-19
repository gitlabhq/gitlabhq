package dependencyproxy

import (
	"context"
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/transport"
)

var httpClient = &http.Client{
	Transport: transport.NewRestrictedTransport(),
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
		fail.Request(w, r, err)
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
	saveFileRequest, err := http.NewRequestWithContext(r.Context(), "POST", r.URL.String()+"/upload", teeReader)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("dependency proxy: failed to create request: %w", err))
	}
	saveFileRequest.Header = r.Header.Clone()

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

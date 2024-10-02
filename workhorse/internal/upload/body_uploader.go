// Package upload provides middleware for handling request bodies and uploading them to a destination.
package upload

import (
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
)

// BodyUploadHandler conforms to the http.Handler interface.
// It also provides an addition function to pass an api.Response.
type BodyUploadHandler interface {
	http.Handler
	ServeHTTPWithAPIResponse(http.ResponseWriter, *http.Request, *api.Response)
}

// RequestBody is a request middleware. It will store the request body to
// a location by determined an api.Response value. It then forwards the
// request to gitlab-rails without the original request body.
func RequestBody(rails PreAuthorizer, h http.Handler, p Preparer) BodyUploadHandler {
	preAuthorizeHandler := rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		processRequestBody(h, p, w, r, a)
	}, "/authorize")
	return &bodyUploadHandlerImpl{preAuthorizeHandler, h, p}
}

type bodyUploadHandlerImpl struct {
	preAuthorizeHandler http.Handler
	httpHandler         http.Handler
	preparer            Preparer
}

func (handler *bodyUploadHandlerImpl) ServeHTTPWithAPIResponse(w http.ResponseWriter, r *http.Request, a *api.Response) {
	processRequestBody(handler.httpHandler, handler.preparer, w, r, a)
}

func (handler *bodyUploadHandlerImpl) ServeHTTP(h http.ResponseWriter, r *http.Request) {
	handler.preAuthorizeHandler.ServeHTTP(h, r)
}

func processRequestBody(h http.Handler, p Preparer, w http.ResponseWriter, r *http.Request, a *api.Response) {
	opts, err := p.Prepare(a)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("RequestBody: preparation failed: %v", err))
		return
	}

	fh, err := destination.Upload(r.Context(), r.Body, r.ContentLength, "upload", opts)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("RequestBody: upload failed: %v", err))
		return
	}

	data := url.Values{}
	fields, err := fh.GitLabFinalizeFields("file")
	if err != nil {
		fail.Request(w, r, fmt.Errorf("RequestBody: finalize fields failed: %v", err))
		return
	}

	for k, v := range fields {
		data.Set(k, v)
	}

	// Hijack body
	body := data.Encode()
	r.Body = io.NopCloser(strings.NewReader(body))
	r.ContentLength = int64(len(body))
	r.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	sft := SavedFileTracker{Request: r}
	sft.Track("file", fh.LocalPath)
	if err := sft.Finalize(r.Context()); err != nil {
		fail.Request(w, r, fmt.Errorf("RequestBody: finalize failed: %v", err))
		return
	}

	// And proxy the request
	h.ServeHTTP(w, r)
}

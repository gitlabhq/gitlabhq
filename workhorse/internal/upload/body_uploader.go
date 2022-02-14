package upload

import (
	"fmt"
	"io/ioutil"
	"net/http"
	"net/url"
	"strings"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

type PreAuthorizer interface {
	PreAuthorizeHandler(next api.HandleFunc, suffix string) http.Handler
}

// Verifier is an optional pluggable behavior for upload paths. If
// Verify() returns an error, Workhorse will return an error response to
// the client instead of propagating the request to Rails. The motivating
// use case is Git LFS, where Workhorse checks the size and SHA256
// checksum of the uploaded file.
type Verifier interface {
	// Verify can abort the upload by returning an error
	Verify(handler *filestore.FileHandler) error
}

// Preparer is a pluggable behavior that interprets a Rails API response
// and either tells Workhorse how to handle the upload, via the
// SaveFileOpts and Verifier, or it rejects the request by returning a
// non-nil error. Its intended use is to make sure the upload gets stored
// in the right location: either a local directory, or one of several
// supported object storage backends.
type Preparer interface {
	Prepare(a *api.Response) (*filestore.SaveFileOpts, Verifier, error)
}

type DefaultPreparer struct{}

func (s *DefaultPreparer) Prepare(a *api.Response) (*filestore.SaveFileOpts, Verifier, error) {
	opts, err := filestore.GetOpts(a)
	return opts, nil, err
}

// RequestBody is a request middleware. It will store the request body to
// a location by determined an api.Response value. It then forwards the
// request to gitlab-rails without the original request body.
func RequestBody(rails PreAuthorizer, h http.Handler, p Preparer) http.Handler {
	return rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		opts, verifier, err := p.Prepare(a)
		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("RequestBody: preparation failed: %v", err))
			return
		}

		fh, err := filestore.SaveFileFromReader(r.Context(), r.Body, r.ContentLength, opts)
		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("RequestBody: upload failed: %v", err))
			return
		}

		if verifier != nil {
			if err := verifier.Verify(fh); err != nil {
				helper.Fail500(w, r, fmt.Errorf("RequestBody: verification failed: %v", err))
				return
			}
		}

		data := url.Values{}
		fields, err := fh.GitLabFinalizeFields("file")
		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("RequestBody: finalize fields failed: %v", err))
			return
		}

		for k, v := range fields {
			data.Set(k, v)
		}

		// Hijack body
		body := data.Encode()
		r.Body = ioutil.NopCloser(strings.NewReader(body))
		r.ContentLength = int64(len(body))
		r.Header.Set("Content-Type", "application/x-www-form-urlencoded")

		sft := SavedFileTracker{Request: r}
		sft.Track("file", fh.LocalPath)
		if err := sft.Finalize(r.Context()); err != nil {
			helper.Fail500(w, r, fmt.Errorf("RequestBody: finalize failed: %v", err))
			return
		}

		// And proxy the request
		h.ServeHTTP(w, r)
	}, "/authorize")
}

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

// Verifier allows to check an upload before sending it to rails
type Verifier interface {
	// Verify can abort the upload returning an error
	Verify(handler *filestore.FileHandler) error
}

// Preparer allows to customize BodyUploader configuration
type Preparer interface {
	// Prepare converts api.Response into a *SaveFileOpts, it can optionally return an Verifier that will be
	// invoked after the real upload, before the finalization with rails
	Prepare(a *api.Response) (*filestore.SaveFileOpts, Verifier, error)
}

type DefaultPreparer struct{}

func (s *DefaultPreparer) Prepare(a *api.Response) (*filestore.SaveFileOpts, Verifier, error) {
	opts, err := filestore.GetOpts(a)
	return opts, nil, err
}

// BodyUploader is an http.Handler that perform a pre authorization call to rails before hijacking the request body and
// uploading it.
// Providing an Preparer allows to customize the upload process
func BodyUploader(rails PreAuthorizer, h http.Handler, p Preparer) http.Handler {
	return rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		opts, verifier, err := p.Prepare(a)
		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("BodyUploader: preparation failed: %v", err))
			return
		}

		fh, err := filestore.SaveFileFromReader(r.Context(), r.Body, r.ContentLength, opts)
		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("BodyUploader: upload failed: %v", err))
			return
		}

		if verifier != nil {
			if err := verifier.Verify(fh); err != nil {
				helper.Fail500(w, r, fmt.Errorf("BodyUploader: verification failed: %v", err))
				return
			}
		}

		data := url.Values{}
		fields, err := fh.GitLabFinalizeFields("file")
		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("BodyUploader: finalize fields failed: %v", err))
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
			helper.Fail500(w, r, fmt.Errorf("BodyUploader: finalize failed: %v", err))
			return
		}

		// And proxy the request
		h.ServeHTTP(w, r)
	}, "/authorize")
}

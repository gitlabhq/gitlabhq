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

// RequestBody is a request middleware. It will store the request body to
// a location by determined an api.Response value. It then forwards the
// request to gitlab-rails without the original request body.
func RequestBody(rails PreAuthorizer, h http.Handler, p Preparer) http.Handler {
	return rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
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
	}, "/authorize")
}

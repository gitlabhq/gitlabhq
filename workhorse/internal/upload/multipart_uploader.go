package upload

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

// Multipart is a request middleware. If the request has a MIME multipart
// request body, the middleware will iterate through the multipart parts.
// When it finds a file part (filename != ""), the middleware will save
// the file contents to a temporary location and replace the file part
// with a reference to the temporary location.
func Multipart(rails PreAuthorizer, h http.Handler, p Preparer) http.Handler {
	return rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		s := &SavedFileTracker{Request: r}

		opts, _, err := p.Prepare(a)
		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("Multipart: error preparing file storage options"))
			return
		}

		interceptMultipartFiles(w, r, h, a, s, opts)
	}, "/authorize")
}

package upload

import (
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

// Multipart is a request middleware. If the request has a MIME multipart
// request body, the middleware will iterate through the multipart parts.
// When it finds a file part (filename != ""), the middleware will save
// the file contents to a temporary location and replace the file part
// with a reference to the temporary location.
func Multipart(rails PreAuthorizer, h http.Handler, p Preparer) http.Handler {
	return rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		s := &SavedFileTracker{Request: r}

		interceptMultipartFiles(w, r, h, s, &eagerAuthorizer{a}, p)
	}, "/authorize")
}

// SkipRailsPreAuthMultipart behaves like Multipart except it does not
// pre-authorize with Rails. It is intended for use on catch-all routes
// where we cannot pre-authorize both because we don't know which Rails
// endpoint to call, and because eagerly pre-authorizing would add too
// much overhead.
func SkipRailsPreAuthMultipart(tempPath string, myAPI *api.API, h http.Handler, p Preparer) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		s := &SavedFileTracker{Request: r}

		// We use testAuthorizer as a temporary measure. When
		// https://gitlab.com/groups/gitlab-com/gl-infra/-/epics/742 is done, we
		// should only be using apiAuthorizer.
		fa := &testAuthorizer{
			test:   &apiAuthorizer{myAPI},
			actual: &eagerAuthorizer{&api.Response{TempPath: tempPath}},
		}

		interceptMultipartFiles(w, r, h, s, fa, p)
	})
}

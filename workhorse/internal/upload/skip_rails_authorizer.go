package upload

import (
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

// SkipRailsAuthorizer implements a fake PreAuthorizer that do not calls rails API and
// authorize each call as a local only upload to TempPath
type SkipRailsAuthorizer struct {
	// TempPath is the temporary path for a local only upload
	TempPath string
}

// PreAuthorizeHandler implements PreAuthorizer. It always grant the upload.
// The fake API response contains only TempPath
func (l *SkipRailsAuthorizer) PreAuthorizeHandler(next api.HandleFunc, _ string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		next(w, r, &api.Response{TempPath: l.TempPath})
	})
}

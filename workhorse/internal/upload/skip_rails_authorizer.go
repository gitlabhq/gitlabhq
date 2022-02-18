package upload

import (
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

// SkipRailsAuthorizer implements a fake PreAuthorizer that does not call
// the gitlab-rails API. It must be fast because it gets called on each
// request proxied to Rails.
type SkipRailsAuthorizer struct {
	// TempPath is a directory where workhorse can store files that can later
	// be accessed by gitlab-rails.
	TempPath string
}

func (l *SkipRailsAuthorizer) PreAuthorizeHandler(next api.HandleFunc, _ string) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		next(w, r, &api.Response{TempPath: l.TempPath})
	})
}

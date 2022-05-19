package upload

import (
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
)

// Preparer is a pluggable behavior that interprets a Rails API response
// and either tells Workhorse how to handle the upload, via the
// UploadOpts, or it rejects the request by returning a non-nil error.
// Its intended use is to make sure the upload gets stored in the right
// location: either a local directory, or one of several supported object
// storage backends.
type Preparer interface {
	Prepare(a *api.Response) (*destination.UploadOpts, error)
}

type DefaultPreparer struct{}

func (s *DefaultPreparer) Prepare(a *api.Response) (*destination.UploadOpts, error) {
	return destination.GetOpts(a)
}

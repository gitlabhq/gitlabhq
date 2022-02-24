package upload

import (
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/filestore"
)

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

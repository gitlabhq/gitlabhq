package upload

import (
	"fmt"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
)

type object struct {
	size int64
	oid  string
}

func (l *object) Verify(fh *destination.FileHandler) error {
	if fh.Size != l.size {
		return fmt.Errorf("LFSObject: expected size %d, wrote %d", l.size, fh.Size)
	}

	if fh.SHA256() != l.oid {
		return fmt.Errorf("LFSObject: expected sha256 %s, got %s", l.oid, fh.SHA256())
	}

	return nil
}

type uploadPreparer struct {
	objectPreparer Preparer
}

// NewLfs returns a new preparer instance which adds capability to a wrapped
// preparer to set options required for a LFS upload.
func NewLfsPreparer(c config.Config, objectPreparer Preparer) Preparer {
	return &uploadPreparer{objectPreparer: objectPreparer}
}

func (l *uploadPreparer) Prepare(a *api.Response) (*destination.UploadOpts, Verifier, error) {
	opts, _, err := l.objectPreparer.Prepare(a)
	if err != nil {
		return nil, nil, err
	}

	opts.TempFilePrefix = a.LfsOid

	return opts, &object{oid: a.LfsOid, size: a.LfsSize}, nil
}

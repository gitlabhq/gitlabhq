/*
In this file we handle git lfs objects downloads and uploads
*/

package lfs

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload"
)

type object struct {
	size int64
	oid  string
}

func (l *object) Verify(fh *filestore.FileHandler) error {
	if fh.Size != l.size {
		return fmt.Errorf("LFSObject: expected size %d, wrote %d", l.size, fh.Size)
	}

	if fh.SHA256() != l.oid {
		return fmt.Errorf("LFSObject: expected sha256 %s, got %s", l.oid, fh.SHA256())
	}

	return nil
}

type uploadPreparer struct {
	objectPreparer upload.Preparer
}

func NewLfsUploadPreparer(c config.Config, objectPreparer upload.Preparer) upload.Preparer {
	return &uploadPreparer{objectPreparer: objectPreparer}
}

func (l *uploadPreparer) Prepare(a *api.Response) (*filestore.SaveFileOpts, upload.Verifier, error) {
	opts, _, err := l.objectPreparer.Prepare(a)
	if err != nil {
		return nil, nil, err
	}

	opts.TempFilePrefix = a.LfsOid

	return opts, &object{oid: a.LfsOid, size: a.LfsSize}, nil
}

func PutStore(a *api.API, h http.Handler, p upload.Preparer) http.Handler {
	return upload.BodyUploader(a, h, p)
}

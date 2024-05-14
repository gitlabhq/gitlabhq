package upload

import (
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
)

// ObjectStoragePreparer prepares objects for upload to object storage.
type ObjectStoragePreparer struct {
	config      config.ObjectStorageConfig
	credentials config.ObjectStorageCredentials
}

// NewObjectStoragePreparer returns a new preparer instance which is responsible for
// setting the object storage credentials and settings needed by an uploader
// to upload to object storage.
func NewObjectStoragePreparer(c config.Config) Preparer {
	return &ObjectStoragePreparer{credentials: c.ObjectStorageCredentials, config: c.ObjectStorageConfig}
}

// Prepare prepares objects for upload to object storage.
func (p *ObjectStoragePreparer) Prepare(a *api.Response) (*destination.UploadOpts, error) {
	opts, err := destination.GetOpts(a)
	if err != nil {
		return nil, err
	}

	opts.ObjectStorageConfig.URLMux = p.config.URLMux
	opts.ObjectStorageConfig.S3Credentials = p.credentials.S3Credentials

	return opts, nil
}

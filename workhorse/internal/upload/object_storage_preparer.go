package upload

import (
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/filestore"
)

type ObjectStoragePreparer struct {
	config      config.ObjectStorageConfig
	credentials config.ObjectStorageCredentials
}

func NewObjectStoragePreparer(c config.Config) Preparer {
	return &ObjectStoragePreparer{credentials: c.ObjectStorageCredentials, config: c.ObjectStorageConfig}
}

func (p *ObjectStoragePreparer) Prepare(a *api.Response) (*filestore.SaveFileOpts, Verifier, error) {
	opts, err := filestore.GetOpts(a)
	if err != nil {
		return nil, nil, err
	}

	opts.ObjectStorageConfig.URLMux = p.config.URLMux
	opts.ObjectStorageConfig.S3Credentials = p.credentials.S3Credentials

	return opts, nil, nil
}

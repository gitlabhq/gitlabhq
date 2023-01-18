package upload

import (
	"testing"

	"gocloud.dev/blob"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"

	"github.com/stretchr/testify/require"
)

func TestPrepareWithS3Config(t *testing.T) {
	creds := config.S3Credentials{
		AwsAccessKeyID:     "test-key",
		AwsSecretAccessKey: "test-secret",
	}

	c := config.Config{
		ObjectStorageCredentials: config.ObjectStorageCredentials{
			Provider:      "AWS",
			S3Credentials: creds,
		},
		ObjectStorageConfig: config.ObjectStorageConfig{
			URLMux: new(blob.URLMux),
		},
	}

	r := &api.Response{
		RemoteObject: api.RemoteObject{
			ID:                 "the ID",
			UseWorkhorseClient: true,
			ObjectStorage: &api.ObjectStorageParams{
				Provider: "AWS",
			},
		},
	}

	p := NewObjectStoragePreparer(c)
	opts, err := p.Prepare(r)

	require.NoError(t, err)
	require.True(t, opts.ObjectStorageConfig.IsAWS())
	require.True(t, opts.UseWorkhorseClient)
	require.Equal(t, creds, opts.ObjectStorageConfig.S3Credentials)
	require.NotNil(t, opts.ObjectStorageConfig.URLMux)
}

func TestPrepareWithNoConfig(t *testing.T) {
	c := config.Config{}
	r := &api.Response{RemoteObject: api.RemoteObject{ID: "id"}}
	p := NewObjectStoragePreparer(c)
	opts, err := p.Prepare(r)

	require.NoError(t, err)
	require.False(t, opts.UseWorkhorseClient)
	require.Nil(t, opts.ObjectStorageConfig.URLMux)
}

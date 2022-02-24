package upload

import (
	"testing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"

	"github.com/stretchr/testify/require"
)

func TestLfsPreparerWithConfig(t *testing.T) {
	lfsOid := "abcd1234"
	creds := config.S3Credentials{
		AwsAccessKeyID:     "test-key",
		AwsSecretAccessKey: "test-secret",
	}

	c := config.Config{
		ObjectStorageCredentials: config.ObjectStorageCredentials{
			Provider:      "AWS",
			S3Credentials: creds,
		},
	}

	r := &api.Response{
		LfsOid: lfsOid,
		RemoteObject: api.RemoteObject{
			ID:                 "the upload ID",
			UseWorkhorseClient: true,
			ObjectStorage: &api.ObjectStorageParams{
				Provider: "AWS",
			},
		},
	}

	uploadPreparer := NewObjectStoragePreparer(c)
	lfsPreparer := NewLfsPreparer(c, uploadPreparer)
	opts, verifier, err := lfsPreparer.Prepare(r)

	require.NoError(t, err)
	require.Equal(t, lfsOid, opts.TempFilePrefix)
	require.True(t, opts.ObjectStorageConfig.IsAWS())
	require.True(t, opts.UseWorkhorseClient)
	require.Equal(t, creds, opts.ObjectStorageConfig.S3Credentials)
	require.NotNil(t, verifier)
}

func TestLfsPreparerWithNoConfig(t *testing.T) {
	c := config.Config{}
	r := &api.Response{RemoteObject: api.RemoteObject{ID: "the upload ID"}}
	uploadPreparer := NewObjectStoragePreparer(c)
	lfsPreparer := NewLfsPreparer(c, uploadPreparer)
	opts, verifier, err := lfsPreparer.Prepare(r)

	require.NoError(t, err)
	require.False(t, opts.UseWorkhorseClient)
	require.NotNil(t, verifier)
}

package lfs_test

import (
	"testing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/lfs"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload"

	"github.com/stretchr/testify/require"
)

func TestLfsUploadPreparerWithConfig(t *testing.T) {
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

	uploadPreparer := upload.NewObjectStoragePreparer(c)
	lfsPreparer := lfs.NewLfsUploadPreparer(c, uploadPreparer)
	opts, verifier, err := lfsPreparer.Prepare(r)

	require.NoError(t, err)
	require.Equal(t, lfsOid, opts.TempFilePrefix)
	require.True(t, opts.ObjectStorageConfig.IsAWS())
	require.True(t, opts.UseWorkhorseClient)
	require.Equal(t, creds, opts.ObjectStorageConfig.S3Credentials)
	require.NotNil(t, verifier)
}

func TestLfsUploadPreparerWithNoConfig(t *testing.T) {
	c := config.Config{}
	r := &api.Response{RemoteObject: api.RemoteObject{ID: "the upload ID"}}
	uploadPreparer := upload.NewObjectStoragePreparer(c)
	lfsPreparer := lfs.NewLfsUploadPreparer(c, uploadPreparer)
	opts, verifier, err := lfsPreparer.Prepare(r)

	require.NoError(t, err)
	require.False(t, opts.UseWorkhorseClient)
	require.NotNil(t, verifier)
}

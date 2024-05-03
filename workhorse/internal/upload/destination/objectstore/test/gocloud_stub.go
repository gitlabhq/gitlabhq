package test

import (
	"context"
	"net/url"
	"testing"

	"github.com/stretchr/testify/require"
	"gocloud.dev/blob"
	"gocloud.dev/blob/fileblob"
)

type dirOpener struct {
	tmpDir string
}

func (o *dirOpener) OpenBucketURL(_ context.Context, _ *url.URL) (*blob.Bucket, error) {
	return fileblob.OpenBucket(o.tmpDir, nil)
}

// SetupGoCloudFileBucket sets up a local GoCloud bucket for testing purposes and returns the URL mux and bucket directory.
func SetupGoCloudFileBucket(t *testing.T, scheme string) (m *blob.URLMux, bucketDir string) {
	tmpDir := t.TempDir()

	mux := new(blob.URLMux)
	fake := &dirOpener{tmpDir: tmpDir}
	mux.RegisterBucket(scheme, fake)

	return mux, tmpDir
}

// GoCloudObjectExists is a helper function for checking if a GoCloud object exists.
func GoCloudObjectExists(t *testing.T, bucketDir string, objectName string) {
	bucket, err := fileblob.OpenBucket(bucketDir, nil)
	require.NoError(t, err)

	ctx, cancel := context.WithCancel(context.Background()) // lint:allow context.Background
	defer cancel()

	exists, err := bucket.Exists(ctx, objectName)
	require.NoError(t, err)
	require.True(t, exists)

	attr, err := bucket.Attributes(ctx, objectName)
	require.NoError(t, err)
	require.Equal(t, "", attr.ContentType)
}

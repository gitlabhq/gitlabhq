package test

import (
	"context"
	"io/ioutil"
	"net/url"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
	"gocloud.dev/blob"
	"gocloud.dev/blob/fileblob"
)

type dirOpener struct {
	tmpDir string
}

func (o *dirOpener) OpenBucketURL(ctx context.Context, u *url.URL) (*blob.Bucket, error) {
	return fileblob.OpenBucket(o.tmpDir, nil)
}

func SetupGoCloudFileBucket(t *testing.T, scheme string) (m *blob.URLMux, bucketDir string, cleanup func()) {
	tmpDir, err := ioutil.TempDir("", "")
	require.NoError(t, err)

	mux := new(blob.URLMux)
	fake := &dirOpener{tmpDir: tmpDir}
	mux.RegisterBucket(scheme, fake)
	cleanup = func() {
		os.RemoveAll(tmpDir)
	}

	return mux, tmpDir, cleanup
}

func GoCloudObjectExists(t *testing.T, bucketDir string, objectName string) {
	bucket, err := fileblob.OpenBucket(bucketDir, nil)
	require.NoError(t, err)

	ctx, cancel := context.WithCancel(context.Background()) // lint:allow context.Background
	defer cancel()

	exists, err := bucket.Exists(ctx, objectName)
	require.NoError(t, err)
	require.True(t, exists)
}

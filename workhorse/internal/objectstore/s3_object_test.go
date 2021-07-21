package objectstore_test

import (
	"context"
	"fmt"
	"io"
	"io/ioutil"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/objectstore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/objectstore/test"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

type failedReader struct {
	io.Reader
}

func (r *failedReader) Read(p []byte) (int, error) {
	origErr := fmt.Errorf("entity is too large")
	return 0, awserr.New("Read", "read failed", origErr)
}

func TestS3ObjectUpload(t *testing.T) {
	testCases := []struct {
		encryption string
	}{
		{encryption: ""},
		{encryption: s3.ServerSideEncryptionAes256},
		{encryption: s3.ServerSideEncryptionAwsKms},
	}

	for _, tc := range testCases {
		t.Run(fmt.Sprintf("encryption=%v", tc.encryption), func(t *testing.T) {
			creds, config, sess, ts := test.SetupS3(t, tc.encryption)
			defer ts.Close()

			deadline := time.Now().Add(testTimeout)
			tmpDir, err := ioutil.TempDir("", "workhorse-test-")
			require.NoError(t, err)
			defer os.Remove(tmpDir)

			objectName := filepath.Join(tmpDir, "s3-test-data")
			ctx, cancel := context.WithCancel(context.Background())

			object, err := objectstore.NewS3Object(objectName, creds, config)
			require.NoError(t, err)

			// copy data
			n, err := object.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
			require.NoError(t, err)
			require.Equal(t, test.ObjectSize, n, "Uploaded file mismatch")

			test.S3ObjectExists(t, sess, config, objectName, test.ObjectContent)
			test.CheckS3Metadata(t, sess, config, objectName)

			cancel()

			testhelper.Retry(t, 5*time.Second, func() error {
				if test.S3ObjectDoesNotExist(t, sess, config, objectName) {
					return nil
				}

				return fmt.Errorf("file is still present")
			})
		})
	}
}

func TestConcurrentS3ObjectUpload(t *testing.T) {
	creds, uploadsConfig, uploadsSession, uploadServer := test.SetupS3WithBucket(t, "uploads", "")
	defer uploadServer.Close()

	// This will return a separate S3 endpoint
	_, artifactsConfig, artifactsSession, artifactsServer := test.SetupS3WithBucket(t, "artifacts", "")
	defer artifactsServer.Close()

	deadline := time.Now().Add(testTimeout)
	tmpDir, err := ioutil.TempDir("", "workhorse-test-")
	require.NoError(t, err)
	defer os.Remove(tmpDir)

	var wg sync.WaitGroup

	for i := 0; i < 4; i++ {
		wg.Add(1)

		go func(index int) {
			var sess *session.Session
			var config config.S3Config

			if index%2 == 0 {
				sess = uploadsSession
				config = uploadsConfig
			} else {
				sess = artifactsSession
				config = artifactsConfig
			}

			name := fmt.Sprintf("s3-test-data-%d", index)
			objectName := filepath.Join(tmpDir, name)
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			object, err := objectstore.NewS3Object(objectName, creds, config)
			require.NoError(t, err)

			// copy data
			n, err := object.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
			require.NoError(t, err)
			require.Equal(t, test.ObjectSize, n, "Uploaded file mismatch")

			test.S3ObjectExists(t, sess, config, objectName, test.ObjectContent)
			wg.Done()
		}(i)
	}

	wg.Wait()
}

func TestS3ObjectUploadCancel(t *testing.T) {
	creds, config, _, ts := test.SetupS3(t, "")
	defer ts.Close()

	ctx, cancel := context.WithCancel(context.Background())

	deadline := time.Now().Add(testTimeout)
	tmpDir, err := ioutil.TempDir("", "workhorse-test-")
	require.NoError(t, err)
	defer os.Remove(tmpDir)

	objectName := filepath.Join(tmpDir, "s3-test-data")

	object, err := objectstore.NewS3Object(objectName, creds, config)

	require.NoError(t, err)

	// Cancel the transfer before the data has been copied to ensure
	// we handle this gracefully.
	cancel()

	_, err = object.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
	require.Error(t, err)
	require.Equal(t, "context canceled", err.Error())
}

func TestS3ObjectUploadLimitReached(t *testing.T) {
	creds, config, _, ts := test.SetupS3(t, "")
	defer ts.Close()

	deadline := time.Now().Add(testTimeout)
	tmpDir, err := ioutil.TempDir("", "workhorse-test-")
	require.NoError(t, err)
	defer os.Remove(tmpDir)

	objectName := filepath.Join(tmpDir, "s3-test-data")
	object, err := objectstore.NewS3Object(objectName, creds, config)
	require.NoError(t, err)

	_, err = object.Consume(context.Background(), &failedReader{}, deadline)
	require.Error(t, err)
	require.Equal(t, "entity is too large", err.Error())
}

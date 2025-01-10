package objectstore

import (
	"context"
	"fmt"
	"io"
	"path/filepath"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/objectstore/test"
)

type s3FailedReader struct {
	io.Reader
}

func (r *s3FailedReader) Read(_ []byte) (int, error) {
	return 0, fmt.Errorf("entity is too large")
}

func TestS3v2ObjectUpload(t *testing.T) {
	testCases := []struct {
		encryption types.ServerSideEncryption
	}{
		{encryption: ""},
		{encryption: types.ServerSideEncryptionAes256},
		{encryption: types.ServerSideEncryptionAwsKms},
	}

	for _, tc := range testCases {
		t.Run(fmt.Sprintf("encryption=%s", string(tc.encryption)), func(t *testing.T) {
			creds, config, client, ts := test.SetupS3(t, string(tc.encryption))
			defer ts.Close()

			deadline := time.Now().Add(testTimeout)
			tmpDir := t.TempDir()

			objectName := filepath.Join(tmpDir, "s3-test-data")
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			object, err := NewS3v2Object(objectName, creds, config)
			require.NoError(t, err)

			// copy data
			n, err := object.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
			require.NoError(t, err)
			require.Equal(t, test.ObjectSize, n, "Uploaded file mismatch")

			test.S3ObjectExists(ctx, t, client, config, object.Name(), test.ObjectContent)
			test.CheckS3Metadata(ctx, t, client, config, object.Name())

			require.Eventually(t, func() bool {
				return (test.S3ObjectDoesNotExist(ctx, t, client, config, objectName))
			}, 5*time.Second, time.Millisecond, "file is still present")
		})
	}
}

func TestConcurrentS3v2ObjectUpload(t *testing.T) {
	creds, uploadsConfig, uploadsClient, uploadServer := test.SetupS3WithBucket(t, "uploads", "")
	defer uploadServer.Close()

	// This will return a separate S3 endpoint
	_, artifactsConfig, artifactsClient, artifactsServer := test.SetupS3WithBucket(t, "artifacts", "")
	defer artifactsServer.Close()

	deadline := time.Now().Add(testTimeout)
	tmpDir := t.TempDir()

	var wg sync.WaitGroup

	for i := 0; i < 4; i++ {
		wg.Add(1)

		go func(index int) {
			var client *s3.Client
			var config config.S3Config

			if index%2 == 0 {
				client = uploadsClient
				config = uploadsConfig
			} else {
				client = artifactsClient
				config = artifactsConfig
			}

			name := fmt.Sprintf("s3-test-data-%d", index)
			objectName := filepath.Join(tmpDir, name)
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			object, err := NewS3v2Object(objectName, creds, config)
			assert.NoError(t, err)

			// copy data
			n, err := object.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
			assert.NoError(t, err)
			assert.Equal(t, test.ObjectSize, n, "Uploaded file mismatch")

			test.S3ObjectExists(ctx, t, client, config, object.Name(), test.ObjectContent)
			wg.Done()
		}(i)
	}

	wg.Wait()
}

func TestS3v2ObjectUploadCancel(t *testing.T) {
	creds, config, _, ts := test.SetupS3(t, "")
	defer ts.Close()

	ctx, cancel := context.WithCancel(context.Background())

	deadline := time.Now().Add(testTimeout)
	tmpDir := t.TempDir()

	objectName := filepath.Join(tmpDir, "s3-test-data")

	object, err := NewS3v2Object(objectName, creds, config)

	require.NoError(t, err)

	// Cancel the transfer before the data has been copied to ensure
	// we handle this gracefully.
	cancel()

	_, err = object.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
	require.Error(t, err)
	require.Equal(t, "read upload data failed: context canceled", err.Error())
}

func TestS3v2ObjectUploadLimitReached(t *testing.T) {
	creds, config, _, ts := test.SetupS3(t, "")
	defer ts.Close()

	deadline := time.Now().Add(testTimeout)
	tmpDir := t.TempDir()

	objectName := filepath.Join(tmpDir, "s3-test-data")
	object, err := NewS3v2Object(objectName, creds, config)
	require.NoError(t, err)

	_, err = object.Consume(context.Background(), &s3FailedReader{}, deadline)
	require.Error(t, err)
	require.Contains(t, err.Error(), "entity is too large")
}

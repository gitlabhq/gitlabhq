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

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/s3/transfermanager"
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

type s3ReaderFunc func([]byte) (int, error)

func (f s3ReaderFunc) Read(p []byte) (int, error) { return f(p) }

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

func TestS3v2ObjectUploadMultipartBoundary(t *testing.T) {
	t.Setenv("AWS_REQUEST_CHECKSUM_CALCULATION", "")
	const multipartThreshold = 16 * 1024 * 1024

	for _, size := range []int{multipartThreshold - 1, multipartThreshold, multipartThreshold + 1} {
		t.Run(fmt.Sprintf("size=%d", size), func(t *testing.T) {
			creds, config, client, ts := test.SetupS3(t, "")
			defer ts.Close()

			object, err := NewS3v2Object("s3-boundary-test", creds, config)
			require.NoError(t, err)

			content := strings.Repeat("0123456789", (size+9)/10)[:size]
			n, err := object.ConsumeWithoutDelete(t.Context(), strings.NewReader(content), time.Now().Add(testTimeout))
			require.NoError(t, err)
			require.Equal(t, int64(size), n)

			test.S3ObjectExists(t.Context(), t, client, config, object.Name(), content)
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

func TestS3v2ObjectUploadMultipartCancel(t *testing.T) {
	t.Setenv("AWS_REQUEST_CHECKSUM_CALCULATION", "")
	creds, cfg, client, ts := test.SetupS3(t, "")
	defer ts.Close()

	object, err := NewS3v2Object("s3-multipart-cancel-test", creds, cfg)
	require.NoError(t, err)
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	reader := io.MultiReader(strings.NewReader(strings.Repeat("a", 16*1024*1024)), s3ReaderFunc(func([]byte) (int, error) {
		cancel()
		return 0, ctx.Err()
	}))

	_, err = object.ConsumeWithoutDelete(ctx, reader, time.Now().Add(testTimeout))
	require.ErrorIs(t, err, context.Canceled)
	var multipartError transfermanager.MultipartUploadError
	require.ErrorAs(t, err, &multipartError)
	require.NotEmpty(t, multipartError.UploadID())
	require.False(t, object.uploaded)

	uploads, err := client.ListMultipartUploads(t.Context(), &s3.ListMultipartUploadsInput{Bucket: aws.String(cfg.Bucket)})
	require.NoError(t, err)
	require.Empty(t, uploads.Uploads)
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

	readCalled := false
	reader := s3ReaderFunc(func([]byte) (int, error) {
		readCalled = true
		return 0, io.EOF
	})

	_, err = object.Consume(ctx, reader, deadline)
	require.ErrorIs(t, err, context.Canceled)
	require.False(t, readCalled, "an already-canceled upload must not read its input")
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

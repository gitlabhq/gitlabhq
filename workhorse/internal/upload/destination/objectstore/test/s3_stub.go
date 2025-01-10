// Package test provides testing utilities for the object store functionality related to Amazon S3.
package test

import (
	"context"
	"io"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go-v2/aws"
	awscfg "github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"

	"github.com/johannesboyne/gofakes3"
	"github.com/johannesboyne/gofakes3/backend/s3mem"
)

// SetupS3 sets up a local S3 server with a default bucket for testing purposes and returns the necessary credentials, configuration, session, and server.
func SetupS3(t *testing.T, encryption string) (config.S3Credentials, config.S3Config, *s3.Client, *httptest.Server) {
	return SetupS3WithBucket(t, "test-bucket", encryption)
}

// SetupS3WithBucket sets up a local S3 server for testing purposes and returns the necessary credentials, configuration, session, and server.
func SetupS3WithBucket(t *testing.T, bucket string, encryption string) (config.S3Credentials, config.S3Config, *s3.Client, *httptest.Server) {
	backend := s3mem.New()
	faker := gofakes3.New(backend)
	ts := httptest.NewServer(faker.Server())

	creds := config.S3Credentials{
		AwsAccessKeyID:     "YOUR-ACCESSKEYID",
		AwsSecretAccessKey: "YOUR-SECRETACCESSKEY",
	}

	cfg := config.S3Config{
		Bucket:    bucket,
		Endpoint:  ts.URL,
		Region:    "eu-central-1",
		PathStyle: true,
	}

	if encryption != "" {
		cfg.ServerSideEncryption = encryption

		if encryption == string(types.ServerSideEncryptionAwsKms) {
			cfg.SSEKMSKeyID = "arn:aws:1234"
		}
	}

	ctx := context.Background() // lint:allow context.Background
	awsCfg, err := awscfg.LoadDefaultConfig(ctx,
		awscfg.WithRegion(cfg.Region),
		awscfg.WithCredentialsProvider(credentials.NewStaticCredentialsProvider(creds.AwsAccessKeyID, creds.AwsSecretAccessKey, "")),
	)
	require.NoError(t, err)

	// Create S3 service client
	client := s3.NewFromConfig(awsCfg, func(o *s3.Options) {
		o.UsePathStyle = true
		o.BaseEndpoint = aws.String(ts.URL)
	})

	_, err = client.CreateBucket(ctx, &s3.CreateBucketInput{
		Bucket: aws.String(bucket),
	})

	require.NoError(t, err)

	return creds, cfg, client, ts
}

// S3ObjectExists will fail the test if the file does not exist.
func S3ObjectExists(ctx context.Context, t *testing.T, client *s3.Client, config config.S3Config, objectName string, expectedBytes string) {
	downloadObject(ctx, t, client, config, objectName, func(tmpfile *os.File, numBytes int64, err error) {
		require.NoError(t, err)
		require.Equal(t, int64(len(expectedBytes)), numBytes)

		output, err := os.ReadFile(tmpfile.Name())
		require.NoError(t, err)

		require.Equal(t, []byte(expectedBytes), output)
	})
}

// CheckS3Metadata is a helper function for testing S3 metadata.
func CheckS3Metadata(ctx context.Context, t *testing.T, client *s3.Client, config config.S3Config, objectName string) {
	result, err := client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(config.Bucket),
		Key:    aws.String(objectName),
	})
	require.NoError(t, err)

	if config.ServerSideEncryption != "" {
		require.Equal(t, config.ServerSideEncryption, string(result.ServerSideEncryption))

		if config.ServerSideEncryption == string(types.ServerSideEncryptionAwsKms) {
			require.Equal(t, aws.String(config.SSEKMSKeyID), result.SSEKMSKeyId)
		} else {
			require.Nil(t, result.SSEKMSKeyId)
		}
	} else {
		require.Empty(t, result.ServerSideEncryption)
		require.Empty(t, result.SSEKMSKeyId)
	}
}

// S3ObjectDoesNotExist returns true if the object has been deleted,
// false otherwise. The return signature is different from
// S3ObjectExists because deletion may need to be retried since deferred
// clean up callsinternal/objectstore/test/s3_stub.go may cause the actual deletion to happen after the
// initial check.
func S3ObjectDoesNotExist(ctx context.Context, t *testing.T, client *s3.Client, config config.S3Config, objectName string) bool {
	deleted := false

	downloadObject(ctx, t, client, config, objectName, func(_ *os.File, _ int64, err error) {
		if err != nil && strings.Contains(err.Error(), "NoSuchKey") {
			deleted = true
		}
	})

	return deleted
}

func downloadObject(ctx context.Context, t *testing.T, client *s3.Client, config config.S3Config, objectName string, handler func(tmpfile *os.File, numBytes int64, err error)) {
	tmpDir := t.TempDir()

	tmpfile, err := os.CreateTemp(tmpDir, "s3-output")
	require.NoError(t, err)

	result, err := client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(config.Bucket),
		Key:    aws.String(objectName),
	})

	numBytes := int64(0)
	if err == nil {
		var copyErr error
		defer func() { _ = result.Body.Close() }()
		numBytes, copyErr = io.Copy(tmpfile, result.Body)
		require.NoError(t, copyErr)
	}

	handler(tmpfile, numBytes, err)
}

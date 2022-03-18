package test

import (
	"io/ioutil"
	"net/http/httptest"
	"os"
	"strings"
	"testing"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"

	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"

	"github.com/johannesboyne/gofakes3"
	"github.com/johannesboyne/gofakes3/backend/s3mem"
)

func SetupS3(t *testing.T, encryption string) (config.S3Credentials, config.S3Config, *session.Session, *httptest.Server) {
	return SetupS3WithBucket(t, "test-bucket", encryption)
}

func SetupS3WithBucket(t *testing.T, bucket string, encryption string) (config.S3Credentials, config.S3Config, *session.Session, *httptest.Server) {
	backend := s3mem.New()
	faker := gofakes3.New(backend)
	ts := httptest.NewServer(faker.Server())

	creds := config.S3Credentials{
		AwsAccessKeyID:     "YOUR-ACCESSKEYID",
		AwsSecretAccessKey: "YOUR-SECRETACCESSKEY",
	}

	config := config.S3Config{
		Bucket:    bucket,
		Endpoint:  ts.URL,
		Region:    "eu-central-1",
		PathStyle: true,
	}

	if encryption != "" {
		config.ServerSideEncryption = encryption

		if encryption == s3.ServerSideEncryptionAwsKms {
			config.SSEKMSKeyID = "arn:aws:1234"
		}
	}

	sess, err := session.NewSession(&aws.Config{
		Credentials:      credentials.NewStaticCredentials(creds.AwsAccessKeyID, creds.AwsSecretAccessKey, ""),
		Endpoint:         aws.String(ts.URL),
		Region:           aws.String(config.Region),
		DisableSSL:       aws.Bool(true),
		S3ForcePathStyle: aws.Bool(true),
	})
	require.NoError(t, err)

	// Create S3 service client
	svc := s3.New(sess)

	_, err = svc.CreateBucket(&s3.CreateBucketInput{
		Bucket: aws.String(bucket),
	})
	require.NoError(t, err)

	return creds, config, sess, ts
}

// S3ObjectExists will fail the test if the file does not exist.
func S3ObjectExists(t *testing.T, sess *session.Session, config config.S3Config, objectName string, expectedBytes string) {
	downloadObject(t, sess, config, objectName, func(tmpfile *os.File, numBytes int64, err error) {
		require.NoError(t, err)
		require.Equal(t, int64(len(expectedBytes)), numBytes)

		output, err := ioutil.ReadFile(tmpfile.Name())
		require.NoError(t, err)

		require.Equal(t, []byte(expectedBytes), output)
	})
}

func CheckS3Metadata(t *testing.T, sess *session.Session, config config.S3Config, objectName string) {
	// In a real S3 provider, s3crypto.NewDecryptionClient should probably be used
	svc := s3.New(sess)
	result, err := svc.GetObject(&s3.GetObjectInput{
		Bucket: aws.String(config.Bucket),
		Key:    aws.String(objectName),
	})
	require.NoError(t, err)

	if config.ServerSideEncryption != "" {
		require.Equal(t, aws.String(config.ServerSideEncryption), result.ServerSideEncryption)

		if config.ServerSideEncryption == s3.ServerSideEncryptionAwsKms {
			require.Equal(t, aws.String(config.SSEKMSKeyID), result.SSEKMSKeyId)
		} else {
			require.Nil(t, result.SSEKMSKeyId)
		}
	} else {
		require.Nil(t, result.ServerSideEncryption)
		require.Nil(t, result.SSEKMSKeyId)
	}
}

// S3ObjectDoesNotExist returns true if the object has been deleted,
// false otherwise. The return signature is different from
// S3ObjectExists because deletion may need to be retried since deferred
// clean up callsinternal/objectstore/test/s3_stub.go may cause the actual deletion to happen after the
// initial check.
func S3ObjectDoesNotExist(t *testing.T, sess *session.Session, config config.S3Config, objectName string) bool {
	deleted := false

	downloadObject(t, sess, config, objectName, func(tmpfile *os.File, numBytes int64, err error) {
		if err != nil && strings.Contains(err.Error(), "NoSuchKey") {
			deleted = true
		}
	})

	return deleted
}

func downloadObject(t *testing.T, sess *session.Session, config config.S3Config, objectName string, handler func(tmpfile *os.File, numBytes int64, err error)) {
	tmpDir, err := ioutil.TempDir("", "workhorse-test-")
	require.NoError(t, err)
	defer os.Remove(tmpDir)

	tmpfile, err := ioutil.TempFile(tmpDir, "s3-output")
	require.NoError(t, err)
	defer os.Remove(tmpfile.Name())

	downloadSvc := s3manager.NewDownloader(sess)
	numBytes, err := downloadSvc.Download(tmpfile, &s3.GetObjectInput{
		Bucket: aws.String(config.Bucket),
		Key:    aws.String(objectName),
	})

	handler(tmpfile, numBytes, err)
}

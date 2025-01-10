package objectstore

import (
	"context"
	"io"
	"path"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/feature/s3/manager"
	"github.com/aws/aws-sdk-go-v2/service/s3"
	"github.com/aws/aws-sdk-go-v2/service/s3/types"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// S3v2Object represents an object stored in Amazon S3.
type S3v2Object struct {
	credentials config.S3Credentials
	config      config.S3Config
	objectName  string
	uploaded    bool

	*uploader
}

// In AWS SDK v1, all URLs are cleaned unless DisableRestProtocolURICleaning is set to true.
// However, this no longer happens automatically in AWS SDK v2.
// In practice, we generally don't create objects with extraneous
// slashes present, but we saw test failures when we mixed AWS SDK v2
// code with the tests that used SDK v1. For example:
//
// 1. Suppose the AWS SDK v2 sends a PUT /bucket//my-object.
// 2. gofakes3 stores the object as /my-object.
// 3. AWS SDK v1 sends GET /bucket/my-object.
// 4. gofakes3 searches for the my-object (without the leading slash) and returns a 404.
//
// See https://docs.aws.amazon.com/sdk-for-go/api/aws/#Config
// and https://github.com/aws/aws-sdk-go/blob/02c1f723b528251a45068001bee8b56d904d7484/private/protocol/rest/build.go#L137-L139
// for more details.
func normalizeKey(key string) string {
	key = path.Clean(key)

	// Strip leading slash
	if len(key) > 0 && key[0] == '/' {
		key = key[1:]
	}

	return key
}

// NewS3v2Object creates a new S3v2Object with the provided object name, S3 credentials, and S3 config.
func NewS3v2Object(objectName string, s3Credentials config.S3Credentials, s3Config config.S3Config) (*S3v2Object, error) {
	o := &S3v2Object{
		credentials: s3Credentials,
		config:      s3Config,
		objectName:  objectName,
	}

	o.uploader = newUploader(o)
	return o, nil
}

func setS3EncryptionOptions(input *s3.PutObjectInput, s3Config config.S3Config) {
	if s3Config.ServerSideEncryption != "" {
		input.ServerSideEncryption = types.ServerSideEncryption(s3Config.ServerSideEncryption)

		if s3Config.ServerSideEncryption == string(types.ServerSideEncryptionAwsKms) && s3Config.SSEKMSKeyID != "" {
			input.SSEKMSKeyId = aws.String(s3Config.SSEKMSKeyID)
		}
	}
}

// Upload uploads the S3 object with the provided context and reader.
func (s *S3v2Object) Upload(ctx context.Context, r io.Reader) error {
	client, err := setupS3Client(s.credentials, s.config)
	if err != nil {
		log.WithError(err).Error("error setting up S3 client in upload")
		return err
	}

	uploader := manager.NewUploader(client)

	input := &s3.PutObjectInput{
		Bucket: aws.String(s.config.Bucket),
		Key:    aws.String(s.Name()),
		Body:   r,
	}

	setS3EncryptionOptions(input, s.config)

	_, err = uploader.Upload(ctx, input)
	if err != nil {
		log.WithError(err).Error("error uploading S3 session")
		return err
	}

	s.uploaded = true

	return nil
}

// ETag returns the ETag of the S3 object.
func (s *S3v2Object) ETag() string {
	return ""
}

// Abort aborts the multipart upload by deleting the object.
func (s *S3v2Object) Abort() {
	s.Delete()
}

// Delete deletes the S3 object if it has been uploaded.
func (s *S3v2Object) Delete() {
	if !s.uploaded {
		return
	}

	client, err := setupS3Client(s.credentials, s.config)
	if err != nil {
		log.WithError(err).Error("error setting up S3 client in delete")
		return
	}

	input := &s3.DeleteObjectInput{
		Bucket: aws.String(s.config.Bucket),
		Key:    aws.String(s.Name()),
	}

	// We can't use the request context because in a successful
	// case, the original request has already completed.
	deleteCtx, cancel := context.WithTimeout(context.Background(), 60*time.Second) // lint:allow context.Background
	defer cancel()

	_, err = client.DeleteObject(deleteCtx, input)
	if err != nil {
		log.WithError(err).Error("error deleting S3 object", err)
	}
}

// Name returns the object name without a leading slash.
func (s *S3v2Object) Name() string {
	return normalizeKey(s.objectName)
}

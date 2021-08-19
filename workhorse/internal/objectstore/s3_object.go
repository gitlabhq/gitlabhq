package objectstore

import (
	"context"
	"io"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/awserr"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/aws/aws-sdk-go/service/s3/s3manager"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

type S3Object struct {
	credentials config.S3Credentials
	config      config.S3Config
	objectName  string
	uploaded    bool

	*uploader
}

func NewS3Object(objectName string, s3Credentials config.S3Credentials, s3Config config.S3Config) (*S3Object, error) {
	o := &S3Object{
		credentials: s3Credentials,
		config:      s3Config,
		objectName:  objectName,
	}

	o.uploader = newUploader(o)
	return o, nil
}

func setEncryptionOptions(input *s3manager.UploadInput, s3Config config.S3Config) {
	if s3Config.ServerSideEncryption != "" {
		input.ServerSideEncryption = aws.String(s3Config.ServerSideEncryption)

		if s3Config.ServerSideEncryption == s3.ServerSideEncryptionAwsKms && s3Config.SSEKMSKeyID != "" {
			input.SSEKMSKeyId = aws.String(s3Config.SSEKMSKeyID)
		}
	}
}

func (s *S3Object) Upload(ctx context.Context, r io.Reader) error {
	sess, err := setupS3Session(s.credentials, s.config)
	if err != nil {
		log.WithError(err).Error("error creating S3 session")
		return err
	}

	uploader := s3manager.NewUploader(sess)

	input := &s3manager.UploadInput{
		Bucket: aws.String(s.config.Bucket),
		Key:    aws.String(s.objectName),
		Body:   r,
	}

	setEncryptionOptions(input, s.config)

	_, err = uploader.UploadWithContext(ctx, input)
	if err != nil {
		log.WithError(err).Error("error uploading S3 session")
		// Get the root cause, such as ErrEntityTooLarge, so we can return the proper HTTP status code
		return unwrapAWSError(err)
	}

	s.uploaded = true

	return nil
}

func (s *S3Object) ETag() string {
	return ""
}

func (s *S3Object) Abort() {
	s.Delete()
}

func (s *S3Object) Delete() {
	if !s.uploaded {
		return
	}

	session, err := setupS3Session(s.credentials, s.config)
	if err != nil {
		log.WithError(err).Error("error setting up S3 session in delete")
		return
	}

	svc := s3.New(session)
	input := &s3.DeleteObjectInput{
		Bucket: aws.String(s.config.Bucket),
		Key:    aws.String(s.objectName),
	}

	// Note we can't use the request context because in a successful
	// case, the original request has already completed.
	deleteCtx, cancel := context.WithTimeout(context.Background(), 60*time.Second) // lint:allow context.Background
	defer cancel()

	_, err = svc.DeleteObjectWithContext(deleteCtx, input)
	if err != nil {
		log.WithError(err).Error("error deleting S3 object", err)
	}
}

// This is needed until https://github.com/aws/aws-sdk-go/issues/2820 is closed.
func unwrapAWSError(e error) error {
	if awsErr, ok := e.(awserr.Error); ok {
		return unwrapAWSError(awsErr.OrigErr())
	}

	return e
}

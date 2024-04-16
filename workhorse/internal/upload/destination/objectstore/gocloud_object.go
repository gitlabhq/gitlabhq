package objectstore

import (
	"context"
	"io"
	"time"

	"gitlab.com/gitlab-org/labkit/log"
	"gocloud.dev/blob"
	"gocloud.dev/gcerrors"
)

type GoCloudObject struct {
	bucket     *blob.Bucket
	mux        *blob.URLMux
	bucketURL  string
	objectName string
	*uploader
}

type GoCloudObjectParams struct {
	Ctx        context.Context
	Mux        *blob.URLMux
	BucketURL  string
	ObjectName string
}

func NewGoCloudObject(p *GoCloudObjectParams) (*GoCloudObject, error) {
	bucket, err := p.Mux.OpenBucket(p.Ctx, p.BucketURL)
	if err != nil {
		return nil, err
	}

	o := &GoCloudObject{
		bucket:     bucket,
		mux:        p.Mux,
		bucketURL:  p.BucketURL,
		objectName: p.ObjectName,
	}

	o.uploader = newUploader(o)
	return o, nil
}

const ChunkSize = 5 * 1024 * 1024

func (o *GoCloudObject) Upload(ctx context.Context, r io.Reader) error {
	defer o.bucket.Close()

	writerOptions := &blob.WriterOptions{
		BufferSize:                  ChunkSize,
		DisableContentTypeDetection: true,
	}
	writer, err := o.bucket.NewWriter(ctx, o.objectName, writerOptions)
	if err != nil {
		log.ContextLogger(ctx).WithError(err).Error("error creating GoCloud bucket")
		return err
	}

	if _, err = io.Copy(writer, r); err != nil {
		log.ContextLogger(ctx).WithError(err).Error("error writing to GoCloud bucket")
		writer.Close()
		return err
	}

	if err := writer.Close(); err != nil {
		log.ContextLogger(ctx).WithError(err).Error("error closing GoCloud bucket")
		return err
	}

	return nil
}

func (o *GoCloudObject) ETag() string {
	return ""
}

func (o *GoCloudObject) Abort() {
	o.Delete()
}

// Delete will always attempt to delete the temporary file.
// According to https://github.com/google/go-cloud/blob/7818961b5c9a112f7e092d3a2d8479cbca80d187/blob/azureblob/azureblob.go#L881-L883,
// if the writer is closed before any Write is called, Close will create an empty file.
func (o *GoCloudObject) Delete() {
	if o.bucketURL == "" || o.objectName == "" {
		return
	}

	// Note we can't use the request context because in a successful
	// case, the original request has already completed.
	deleteCtx, cancel := context.WithTimeout(context.Background(), 60*time.Second) // lint:allow context.Background
	defer cancel()

	bucket, err := o.mux.OpenBucket(deleteCtx, o.bucketURL)
	if err != nil {
		log.WithError(err).Error("error opening bucket for delete")
		return
	}

	if err := bucket.Delete(deleteCtx, o.objectName); err != nil {
		if gcerrors.Code(err) != gcerrors.NotFound {
			log.WithError(err).Error("error deleting object")
		}
	}
}

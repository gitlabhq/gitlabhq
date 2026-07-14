package objectstore

import (
	"context"
	"crypto/md5" //nolint:gosec // G501: MD5 required for S3 ETag verification per AWS S3 protocol
	"encoding/hex"
	"fmt"
	"hash"
	"io"
	"strings"
	"sync/atomic"
	"time"

	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/v2/fields"
)

// uploader consumes an io.Reader and uploads it using a pluggable uploadStrategy.
type uploader struct {
	strategy uploadStrategy

	// In the case of S3 uploads, we have a multipart upload which
	// instantiates uploads for the individual parts. We don't want to
	// increment metrics for the individual parts, so that is why we have
	// this boolean flag.
	//
	// It also gates the per-upload summary log (see logUploadSummary in
	// consume): individual parts have metrics=false so that a multipart
	// upload emits a single summary instead of one per part. Changing this
	// gating would break that dedup behavior.
	metrics bool

	// With S3 we compare the MD5 of the data we sent with the ETag returned
	// by the object storage server.
	checkETag bool
}

func newUploader(strategy uploadStrategy) *uploader {
	return &uploader{strategy: strategy, metrics: true}
}

func newETagCheckUploader(strategy uploadStrategy, metrics bool) *uploader {
	return &uploader{strategy: strategy, metrics: metrics, checkETag: true}
}

func hexString(h hash.Hash) string { return hex.EncodeToString(h.Sum(nil)) }

func (u *uploader) Consume(outerCtx context.Context, reader io.Reader, deadLine time.Time) (_ int64, err error) {
	return u.consume(outerCtx, reader, deadLine, false)
}

func (u *uploader) ConsumeWithoutDelete(outerCtx context.Context, reader io.Reader, deadLine time.Time) (_ int64, err error) {
	return u.consume(outerCtx, reader, deadLine, true)
}

// Consume reads the reader until it reaches EOF or an error. It spawns a
// goroutine that waits for outerCtx to be done, after which the remote
// file is deleted. The deadline applies to the upload performed inside
// Consume, not to outerCtx.
// SkipDelete optionaly call the Delete() function on the strategy once
// rails is done handling the upload request.
func (u *uploader) consume(outerCtx context.Context, reader io.Reader, deadLine time.Time, skipDelete bool) (_ int64, err error) {
	// cr is declared early so the deferred summary log can read cr.n;
	// cr.r is assigned later, after the optional TeeReader wrapping.
	cr := &countReader{}

	if u.metrics {
		objectStorageUploadsOpen.Inc()
		defer func(started time.Time) {
			objectStorageUploadsOpen.Dec()
			elapsed := time.Since(started)
			objectStorageUploadTime.Observe(elapsed.Seconds())
			if err != nil {
				objectStorageUploadRequestsRequestFailed.Inc()
			}

			// Gated by u.metrics so each top-level upload emits one summary;
			// per-part uploads have metrics=false (see the metrics field doc).
			u.logUploadSummary(outerCtx, elapsed, cr.n.Load(), err)
		}(time.Now())
	}

	defer func() {
		// We do this mainly to abort S3 multipart uploads: it is not enough to
		// "delete" them.
		if err != nil {
			u.strategy.Abort()

			if skipDelete {
				// skipDelete avoided the object removal (see the goroutine below). Make
				// here that the object is deleted if aborted.
				u.strategy.Delete()
			}
		}
	}()

	if !skipDelete {
		go func() {
			// Once gitlab-rails is done handling the request, we are supposed to
			// delete the upload from its temporary location.
			<-outerCtx.Done()
			u.strategy.Delete()
		}()
	}

	uploadCtx, cancelFn := context.WithDeadline(outerCtx, deadLine)
	defer cancelFn()

	var hasher hash.Hash
	if u.checkETag {
		hasher = md5.New() //nolint:gosec // G401: MD5 required for S3 ETag verification
		reader = io.TeeReader(reader, hasher)
	}

	cr.r = reader
	if err := u.strategy.Upload(uploadCtx, cr); err != nil {
		return 0, err
	}

	if u.checkETag {
		if err := compareMD5(hexString(hasher), u.strategy.ETag()); err != nil {
			log.ContextLogger(uploadCtx).WithError(err).Error("error comparing MD5 checksum")
			return 0, err
		}
	}

	objectStorageUploadBytes.Add(float64(cr.n.Load()))

	return cr.n.Load(), nil
}

func (u *uploader) logUploadSummary(ctx context.Context, elapsed time.Duration, bytes int64, err error) {
	logFields := log.Fields{
		"strategy":       u.strategy.Strategy(),
		fields.DurationS: elapsed.Seconds(),
		"uploaded_bytes": bytes,
	}

	if err != nil {
		logFields[fields.ErrorMessage] = err.Error()
	}

	log.WithContextFields(ctx, logFields).Info("object storage upload completed")
}

func compareMD5(local, remote string) error {
	if !strings.EqualFold(local, remote) {
		return fmt.Errorf("ETag mismatch. expected %q got %q", local, remote)
	}

	return nil
}

type countReader struct {
	r io.Reader
	n atomic.Int64
}

func (cr *countReader) Read(p []byte) (int, error) {
	nRead, err := cr.r.Read(p)
	cr.n.Add(int64(nRead))
	return nRead, err
}

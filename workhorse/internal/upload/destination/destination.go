// Package destination handles uploading to a specific destination (delegates
// to filestore or objectstore packages) based on options from the pre-authorization
// API and finalizing the upload.
package destination

import (
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"strconv"
	"time"

	"github.com/golang-jwt/jwt/v5"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/filestore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/objectstore"
)

// SizeError represents an error related to the size of a file or data.
type SizeError error

// ErrEntityTooLarge means that the uploaded content is bigger then maximum allowed size
var ErrEntityTooLarge = errors.New("entity is too large")

// FileHandler represent a file that has been processed for upload
// it may be either uploaded to an ObjectStore and/or saved on local path.
type FileHandler struct {
	// LocalPath is the path on the disk where file has been stored
	LocalPath string

	// RemoteID is the objectID provided by GitLab Rails
	RemoteID string
	// RemoteURL is ObjectStore URL provided by GitLab Rails
	RemoteURL string

	// Size is the persisted file size
	Size int64

	// Name is the resource name to send back to GitLab rails.
	// It differ from the real file name in order to avoid file collisions
	Name string

	// a map containing different hashes
	hashes map[string]string

	// Duration of upload in seconds
	uploadDuration float64
}

type uploadClaims struct {
	Upload map[string]string `json:"upload"`
	jwt.RegisteredClaims
}

// SHA256 hash of the handled file
func (fh *FileHandler) SHA256() string {
	return fh.hashes["sha256"]
}

// MD5 hash of the handled file
func (fh *FileHandler) MD5() string {
	return fh.hashes["md5"]
}

// GitLabFinalizeFields returns a map with all the fields GitLab Rails needs in order to finalize the upload.
func (fh *FileHandler) GitLabFinalizeFields(prefix string) (map[string]string, error) {
	// TODO: remove `data` these once rails fully and exclusively support `signedData` (https://gitlab.com/gitlab-org/gitlab/-/issues/324873)
	data := make(map[string]string)
	signedData := make(map[string]string)
	key := func(field string) string {
		if prefix == "" {
			return field
		}

		return fmt.Sprintf("%s.%s", prefix, field)
	}

	for k, v := range map[string]string{
		"name":            fh.Name,
		"path":            fh.LocalPath,
		"remote_url":      fh.RemoteURL,
		"remote_id":       fh.RemoteID,
		"size":            strconv.FormatInt(fh.Size, 10),
		"upload_duration": strconv.FormatFloat(fh.uploadDuration, 'f', -1, 64),
	} {
		data[key(k)] = v
		signedData[k] = v
	}

	for hashName, hash := range fh.hashes {
		data[key(hashName)] = hash
		signedData[hashName] = hash
	}

	claims := uploadClaims{Upload: signedData, RegisteredClaims: secret.DefaultClaims}
	jwtData, err := secret.JWTTokenString(claims)
	if err != nil {
		return nil, err
	}
	data[key("gitlab-workhorse-upload")] = jwtData

	return data, nil
}

type consumer interface {
	Consume(context.Context, io.Reader, time.Time) (int64, error)
	ConsumeWithoutDelete(context.Context, io.Reader, time.Time) (int64, error)
}

// Upload persists the provided reader content to all the location specified in opts. A cleanup will be performed once ctx is Done
// Make sure the provided context will not expire before finalizing upload with GitLab Rails.
func Upload(ctx context.Context, reader io.Reader, size int64, name string, opts *UploadOpts) (*FileHandler, error) {
	fh := &FileHandler{
		Name:      name,
		RemoteID:  opts.RemoteID,
		RemoteURL: opts.RemoteURL,
	}
	uploadStartTime := time.Now()
	defer func() { fh.uploadDuration = time.Since(uploadStartTime).Seconds() }()
	hashes := newMultiHash(opts.UploadHashFunctions)
	reader = io.TeeReader(reader, hashes.Writer)

	clientMode, uploadDestination, err := getClientInformation(ctx, opts, fh, size)

	if err != nil {
		return nil, err
	}

	var hlr *hardLimitReader
	if opts.MaximumSize > 0 {
		if size > opts.MaximumSize {
			return nil, SizeError(fmt.Errorf("the upload size %d is over maximum of %d bytes", size, opts.MaximumSize))
		}

		hlr = &hardLimitReader{r: reader, n: opts.MaximumSize}
		reader = hlr
	}

	if opts.SkipDelete {
		fh.Size, err = uploadDestination.ConsumeWithoutDelete(ctx, reader, opts.Deadline)
	} else {
		fh.Size, err = uploadDestination.Consume(ctx, reader, opts.Deadline)
	}

	if err != nil {
		if (err == objectstore.ErrNotEnoughParts) || (hlr != nil && hlr.n < 0) {
			err = ErrEntityTooLarge
		}
		return nil, err
	}

	if size != -1 && size != fh.Size {
		return nil, SizeError(fmt.Errorf("expected %d bytes but got only %d", size, fh.Size))
	}

	logger := log.WithContextFields(ctx, log.Fields{
		"copied_bytes": fh.Size,
		"is_local":     opts.IsLocalTempFile(),
		"is_multipart": opts.IsMultipart(),
		"is_remote":    !opts.IsLocalTempFile(),
		"remote_id":    opts.RemoteID,
		"client_mode":  clientMode,
		"filename":     fh.Name,
	})

	if opts.IsLocalTempFile() {
		logger = logger.WithField("local_temp_path", opts.LocalTempPath)
	} else {
		logger = logger.WithField("remote_temp_object", opts.RemoteTempObjectID)
	}

	logger.Info("saved file")
	fh.hashes = hashes.finish()
	return fh, nil
}

func getClientInformation(ctx context.Context, opts *UploadOpts, fh *FileHandler, size int64) (string, consumer, error) {
	var clientMode string
	var uploadDestination consumer
	var err error
	switch {
	// This case means Workhorse is acting as an upload proxy for Rails and buffers files
	// to disk in a temporary location, see:
	// https://docs.gitlab.com/ee/development/uploads/#rails-controller-upload
	case opts.IsLocalTempFile():
		clientMode = "local_tempfile"
		uploadDestination, err = fh.newLocalFile(ctx, opts)

	// All cases below mean we are doing a direct upload to remote i.e. object storage, see:
	// https://docs.gitlab.com/ee/development/uploads/#direct-upload
	case opts.UseWorkhorseClientEnabled() && opts.ObjectStorageConfig.IsGoCloud():
		clientMode = fmt.Sprintf("go_cloud:%s", opts.ObjectStorageConfig.Provider)
		p := &objectstore.GoCloudObjectParams{
			Ctx:        ctx,
			Mux:        opts.ObjectStorageConfig.URLMux,
			BucketURL:  opts.ObjectStorageConfig.GoCloudConfig.URL,
			ObjectName: opts.RemoteTempObjectID,
		}
		uploadDestination, err = objectstore.NewGoCloudObject(p)
	case opts.UseWorkhorseClientEnabled() && opts.ObjectStorageConfig.IsAWS() && opts.ObjectStorageConfig.IsValid():
		clientMode = "s3_client_v2"
		uploadDestination, err = objectstore.NewS3v2Object(
			opts.RemoteTempObjectID,
			opts.ObjectStorageConfig.S3Credentials,
			opts.ObjectStorageConfig.S3Config,
		)
	case opts.IsMultipart():
		clientMode = "s3_multipart"
		uploadDestination, err = objectstore.NewMultipart(
			opts.PresignedParts,
			opts.PresignedCompleteMultipart,
			opts.PresignedAbortMultipart,
			opts.PresignedDelete,
			opts.PutHeaders,
			opts.PartSize,
		)
	default:
		clientMode = "presigned_put"
		uploadDestination, err = objectstore.NewObject(
			opts.PresignedPut,
			opts.PresignedDelete,
			opts.PutHeaders,
			size,
		)
	}
	return clientMode, uploadDestination, err
}

func (fh *FileHandler) newLocalFile(ctx context.Context, opts *UploadOpts) (consumer, error) {
	// make sure TempFolder exists
	err := os.MkdirAll(opts.LocalTempPath, 0700)
	if err != nil {
		return nil, fmt.Errorf("newLocalFile: mkdir %q: %v", opts.LocalTempPath, err)
	}

	file, err := os.CreateTemp(opts.LocalTempPath, "gitlab-workhorse-upload")
	if err != nil {
		return nil, fmt.Errorf("newLocalFile: create file: %v", err)
	}

	go func() {
		<-ctx.Done()
		if err := os.Remove(file.Name()); err != nil {
			fmt.Printf("newLocalFile: remove file %q: %v", file.Name(), err)
		}
	}()

	fh.LocalPath = file.Name()
	return &filestore.LocalFile{File: file}, nil
}

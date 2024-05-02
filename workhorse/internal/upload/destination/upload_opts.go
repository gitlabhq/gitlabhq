package destination

import (
	"errors"
	"strings"
	"time"

	"gocloud.dev/blob"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// DefaultObjectStoreTimeout is the timeout for ObjectStore upload operation
const DefaultObjectStoreTimeout = 4 * time.Hour

// ObjectStorageConfig holds configuration details for object storage destinations.
type ObjectStorageConfig struct {
	Provider string

	S3Credentials config.S3Credentials
	S3Config      config.S3Config

	// GoCloud mux that maps azureblob:// and future URLs (e.g. s3://, gcs://, etc.) to a handler
	URLMux *blob.URLMux

	// Azure credentials are registered at startup in the GoCloud URLMux, so only the container name is needed
	GoCloudConfig config.GoCloudConfig
}

// UploadOpts represents all the options available for saving a file to object store
type UploadOpts struct {
	// LocalTempPath is the directory where to write a local copy of the file
	LocalTempPath string
	// RemoteID is the remote ObjectID provided by GitLab
	RemoteID string
	// RemoteURL is the final URL of the file
	RemoteURL string
	// PresignedPut is a presigned S3 PutObject compatible URL
	PresignedPut string
	// PresignedDelete is a presigned S3 DeleteObject compatible URL.
	PresignedDelete string
	// Whether Workhorse needs to delete the temporary object or not.
	SkipDelete bool
	// HTTP headers to be sent along with PUT request
	PutHeaders map[string]string
	// Whether to ignore Rails pre-signed URLs and have Workhorse directly access object storage provider
	UseWorkhorseClient bool
	// If UseWorkhorseClient is true, this is the temporary object name to store the file
	RemoteTempObjectID string
	// Workhorse object storage client (e.g. S3) parameters
	ObjectStorageConfig ObjectStorageConfig
	// Deadline it the S3 operation deadline, the upload will be aborted if not completed in time
	Deadline time.Time
	// The maximum accepted size in bytes of the upload
	MaximumSize int64

	// MultipartUpload parameters
	// PartSize is the exact size of each uploaded part. Only the last one can be smaller
	PartSize int64
	// PresignedParts contains the presigned URLs for each part
	PresignedParts []string
	// PresignedCompleteMultipart is a presigned URL for CompleteMulipartUpload
	PresignedCompleteMultipart string
	// PresignedAbortMultipart is a presigned URL for AbortMultipartUpload
	PresignedAbortMultipart string
	// UploadHashFunctions contains a list of allowed hash functions (md5, sha1, etc.)
	UploadHashFunctions []string
}

// UseWorkhorseClientEnabled checks if the options require direct access to object storage
func (s *UploadOpts) UseWorkhorseClientEnabled() bool {
	return s.UseWorkhorseClient && s.ObjectStorageConfig.IsValid() && s.RemoteTempObjectID != ""
}

// IsLocalTempFile checks if the options require the writing of a temporary file on disk
func (s *UploadOpts) IsLocalTempFile() bool {
	return s.LocalTempPath != ""
}

// IsMultipart checks if the options requires a Multipart upload
func (s *UploadOpts) IsMultipart() bool {
	return s.PartSize > 0
}

// GetOpts converts GitLab api.Response to a proper UploadOpts
func GetOpts(apiResponse *api.Response) (*UploadOpts, error) {
	timeout := time.Duration(
		// By converting time.Second to a float32 value we can correctly handle
		// small Timeout values like 0.1.
		apiResponse.RemoteObject.Timeout * float32(time.Second),
	)
	if timeout == 0 {
		timeout = DefaultObjectStoreTimeout
	}

	opts := UploadOpts{
		LocalTempPath:       apiResponse.TempPath,
		RemoteID:            apiResponse.RemoteObject.ID,
		RemoteURL:           apiResponse.RemoteObject.GetURL,
		PresignedPut:        apiResponse.RemoteObject.StoreURL,
		PresignedDelete:     apiResponse.RemoteObject.DeleteURL,
		SkipDelete:          apiResponse.RemoteObject.SkipDelete,
		PutHeaders:          apiResponse.RemoteObject.PutHeaders,
		UseWorkhorseClient:  apiResponse.RemoteObject.UseWorkhorseClient,
		RemoteTempObjectID:  apiResponse.RemoteObject.RemoteTempObjectID,
		Deadline:            time.Now().Add(timeout),
		MaximumSize:         apiResponse.MaximumSize,
		UploadHashFunctions: apiResponse.UploadHashFunctions,
	}

	if opts.LocalTempPath != "" && opts.RemoteID != "" {
		return nil, errors.New("API response has both TempPath and RemoteObject")
	}

	if opts.LocalTempPath == "" && opts.RemoteID == "" {
		return nil, errors.New("API response has neither TempPath nor RemoteObject")
	}

	objectStorageParams := apiResponse.RemoteObject.ObjectStorage
	if opts.UseWorkhorseClient && objectStorageParams != nil {
		opts.ObjectStorageConfig.Provider = objectStorageParams.Provider
		opts.ObjectStorageConfig.S3Config = objectStorageParams.S3Config
		opts.ObjectStorageConfig.GoCloudConfig = objectStorageParams.GoCloudConfig
	}

	// Backwards compatibility to ensure API servers that do not include the
	// CustomPutHeaders flag will default to the original content type.
	if !apiResponse.RemoteObject.CustomPutHeaders {
		opts.PutHeaders = make(map[string]string)
		opts.PutHeaders["Content-Type"] = "application/octet-stream"
	}

	if multiParams := apiResponse.RemoteObject.MultipartUpload; multiParams != nil {
		opts.PartSize = multiParams.PartSize
		opts.PresignedCompleteMultipart = multiParams.CompleteURL
		opts.PresignedAbortMultipart = multiParams.AbortURL
		opts.PresignedParts = append([]string(nil), multiParams.PartURLs...)
	}

	return &opts, nil
}

// IsAWS checks if the object storage provider is AWS S3.
func (c *ObjectStorageConfig) IsAWS() bool {
	return strings.EqualFold(c.Provider, "AWS") || strings.EqualFold(c.Provider, "S3")
}

// IsAzure checks if the object storage provider is Azure Blob Storage.
func (c *ObjectStorageConfig) IsAzure() bool {
	return strings.EqualFold(c.Provider, "AzureRM")
}

// IsGoCloud checks if the object storage provider is configured to use GoCloud.
func (c *ObjectStorageConfig) IsGoCloud() bool {
	return c.GoCloudConfig.URL != ""
}

// IsValid checks if the object storage configuration is valid.
func (c *ObjectStorageConfig) IsValid() bool {
	if c.IsAWS() {
		return c.S3Config.Bucket != "" && c.s3CredentialsValid()
	} else if c.IsGoCloud() {
		// We could parse and validate the URL, but GoCloud providers
		// such as AzureRM don't have a fallback to normal HTTP, so we
		// always want to try the GoCloud path if there is a URL.
		return true
	}

	return false
}

func (c *ObjectStorageConfig) s3CredentialsValid() bool {
	// We need to be able to distinguish between two cases of AWS access:
	// 1. AWS access via key and secret, but credentials not configured in Workhorse
	// 2. IAM instance profiles used
	if c.S3Config.UseIamProfile {
		return true
	} else if c.S3Credentials.AwsAccessKeyID != "" && c.S3Credentials.AwsSecretAccessKey != "" {
		return true
	}

	return false
}

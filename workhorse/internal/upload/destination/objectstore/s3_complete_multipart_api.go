package objectstore

import (
	"encoding/xml"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/objectstore/s3api"
)

// compoundCompleteMultipartUploadResult holds both CompleteMultipartUploadResult and CompleteMultipartUploadError
// this allow us to deserialize the response body where the root element can either be Error orCompleteMultipartUploadResult
type compoundCompleteMultipartUploadResult struct {
	*s3api.CompleteMultipartUploadResult
	*s3api.CompleteMultipartUploadError

	// XMLName this overrides CompleteMultipartUploadError.XMLName tags
	XMLName xml.Name
}

func (c *compoundCompleteMultipartUploadResult) isError() bool {
	return c.CompleteMultipartUploadError != nil
}

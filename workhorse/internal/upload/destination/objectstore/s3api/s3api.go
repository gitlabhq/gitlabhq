// Package s3api provides functionality for interacting with the Amazon S3 API.
package s3api

import (
	"encoding/xml"
	"fmt"
)

// CompleteMultipartUploadError is the in-body error structure
// https://docs.aws.amazon.com/AmazonS3/latest/API/mpUploadComplete.html#mpUploadComplete-examples
// the answer contains other fields we are not using
type CompleteMultipartUploadError struct {
	XMLName xml.Name `xml:"Error"`
	Code    string
	Message string
}

func (c *CompleteMultipartUploadError) Error() string {
	return fmt.Sprintf("CompleteMultipartUpload remote error %q: %s", c.Code, c.Message)
}

// CompleteMultipartUploadResult is the S3 answer to CompleteMultipartUpload request
type CompleteMultipartUploadResult struct {
	Location string
	Bucket   string
	Key      string
	ETag     string
}

// CompleteMultipartUpload is the S3 CompleteMultipartUpload body
type CompleteMultipartUpload struct {
	Part []*CompleteMultipartUploadPart
}

// CompleteMultipartUploadPart represents a part of a completed multipart upload.
type CompleteMultipartUploadPart struct {
	PartNumber int
	ETag       string
}

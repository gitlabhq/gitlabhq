package objectstore

import (
	"encoding/xml"
	"fmt"
)

// CompleteMultipartUpload is the S3 CompleteMultipartUpload body
type CompleteMultipartUpload struct {
	Part []*completeMultipartUploadPart
}

type completeMultipartUploadPart struct {
	PartNumber int
	ETag       string
}

// CompleteMultipartUploadResult is the S3 answer to CompleteMultipartUpload request
type CompleteMultipartUploadResult struct {
	Location string
	Bucket   string
	Key      string
	ETag     string
}

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

// compoundCompleteMultipartUploadResult holds both CompleteMultipartUploadResult and CompleteMultipartUploadError
// this allow us to deserialize the response body where the root element can either be Error orCompleteMultipartUploadResult
type compoundCompleteMultipartUploadResult struct {
	*CompleteMultipartUploadResult
	*CompleteMultipartUploadError

	// XMLName this overrides CompleteMultipartUploadError.XMLName tags
	XMLName xml.Name
}

func (c *compoundCompleteMultipartUploadResult) isError() bool {
	return c.CompleteMultipartUploadError != nil
}

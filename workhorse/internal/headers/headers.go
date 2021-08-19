package headers

import (
	"net/http"
	"strconv"
)

// Max number of bytes that http.DetectContentType needs to get the content type
// Fixme: Go back to 512 bytes once https://gitlab.com/gitlab-org/gitlab/-/issues/325074
// has been merged
const MaxDetectSize = 4096

// HTTP Headers
const (
	ContentDispositionHeader = "Content-Disposition"
	ContentTypeHeader        = "Content-Type"

	// Workhorse related headers
	GitlabWorkhorseSendDataHeader = "Gitlab-Workhorse-Send-Data"
	XSendFileHeader               = "X-Sendfile"
	XSendFileTypeHeader           = "X-Sendfile-Type"

	// Signal header that indicates Workhorse should detect and set the content headers
	GitlabWorkhorseDetectContentTypeHeader = "Gitlab-Workhorse-Detect-Content-Type"
)

var ResponseHeaders = []string{
	XSendFileHeader,
	GitlabWorkhorseSendDataHeader,
	GitlabWorkhorseDetectContentTypeHeader,
}

func IsDetectContentTypeHeaderPresent(rw http.ResponseWriter) bool {
	header, err := strconv.ParseBool(rw.Header().Get(GitlabWorkhorseDetectContentTypeHeader))
	if err != nil || !header {
		return false
	}

	return true
}

// AnyResponseHeaderPresent checks in the ResponseWriter if there is any Response Header
func AnyResponseHeaderPresent(rw http.ResponseWriter) bool {
	// If this header is not present means that we want the old behavior
	if !IsDetectContentTypeHeaderPresent(rw) {
		return false
	}

	for _, header := range ResponseHeaders {
		if rw.Header().Get(header) != "" {
			return true
		}
	}
	return false
}

// RemoveResponseHeaders removes any ResponseHeader from the ResponseWriter
func RemoveResponseHeaders(rw http.ResponseWriter) {
	for _, header := range ResponseHeaders {
		rw.Header().Del(header)
	}
}

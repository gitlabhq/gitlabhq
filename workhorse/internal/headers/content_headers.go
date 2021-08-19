package headers

import (
	"net/http"
	"regexp"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/utils/svg"
)

var (
	ImageTypeRegex   = regexp.MustCompile(`^image/*`)
	SvgMimeTypeRegex = regexp.MustCompile(`^image/svg\+xml$`)

	TextTypeRegex = regexp.MustCompile(`^text/*`)

	VideoTypeRegex = regexp.MustCompile(`^video/*`)

	PdfTypeRegex = regexp.MustCompile(`application\/pdf`)

	AttachmentRegex = regexp.MustCompile(`^attachment`)
	InlineRegex     = regexp.MustCompile(`^inline`)
)

// Mime types that can't be inlined. Usually subtypes of main types
var forbiddenInlineTypes = []*regexp.Regexp{SvgMimeTypeRegex}

// Mime types that can be inlined. We can add global types like "image/" or
// specific types like "text/plain". If there is a specific type inside a global
// allowed type that can't be inlined we must add it to the forbiddenInlineTypes var.
// One example of this is the mime type "image". We allow all images to be
// inlined except for SVGs.
var allowedInlineTypes = []*regexp.Regexp{ImageTypeRegex, TextTypeRegex, VideoTypeRegex, PdfTypeRegex}

func SafeContentHeaders(data []byte, contentDisposition string) (string, string) {
	contentType := safeContentType(data)
	contentDisposition = safeContentDisposition(contentType, contentDisposition)
	return contentType, contentDisposition
}

func safeContentType(data []byte) string {
	// Special case for svg because DetectContentType detects it as text
	if svg.Is(data) {
		return "image/svg+xml"
	}

	// Override any existing Content-Type header from other ResponseWriters
	contentType := http.DetectContentType(data)

	// If the content is text type, we set to plain, because we don't
	// want to render it inline if they're html or javascript
	if isType(contentType, TextTypeRegex) {
		return "text/plain; charset=utf-8"
	}

	return contentType
}

func safeContentDisposition(contentType string, contentDisposition string) string {
	// If the existing disposition is attachment we return that. This allow us
	// to force a download from GitLab (ie: RawController)
	if AttachmentRegex.MatchString(contentDisposition) {
		return contentDisposition
	}

	// Checks for mime types that are forbidden to be inline
	for _, element := range forbiddenInlineTypes {
		if isType(contentType, element) {
			return attachmentDisposition(contentDisposition)
		}
	}

	// Checks for mime types allowed to be inline
	for _, element := range allowedInlineTypes {
		if isType(contentType, element) {
			return inlineDisposition(contentDisposition)
		}
	}

	// Anything else is set to attachment
	return attachmentDisposition(contentDisposition)
}

func attachmentDisposition(contentDisposition string) string {
	if contentDisposition == "" {
		return "attachment"
	}

	if InlineRegex.MatchString(contentDisposition) {
		return InlineRegex.ReplaceAllString(contentDisposition, "attachment")
	}

	return contentDisposition
}

func inlineDisposition(contentDisposition string) string {
	if contentDisposition == "" {
		return "inline"
	}

	if AttachmentRegex.MatchString(contentDisposition) {
		return AttachmentRegex.ReplaceAllString(contentDisposition, "inline")
	}

	return contentDisposition
}

func isType(contentType string, mimeType *regexp.Regexp) bool {
	return mimeType.MatchString(contentType)
}

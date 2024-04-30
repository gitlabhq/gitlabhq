package headers

import (
	"mime"
	"net/http"
	"regexp"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/utils/svg"
)

var (
	javaScriptTypeRegex = regexp.MustCompile(`^(text|application)\/javascript$`)

	imageTypeRegex   = regexp.MustCompile(`^image/*`)
	svgMimeTypeRegex = regexp.MustCompile(`^image/svg\+xml$`)

	textTypeRegex  = regexp.MustCompile(`^text/*`)
	xmlTypeRegex   = regexp.MustCompile(`^text/xml`)
	xhtmlTypeRegex = regexp.MustCompile(`^text/html`)
	videoTypeRegex = regexp.MustCompile(`^video/*`)

	pdfTypeRegex = regexp.MustCompile(`application\/pdf`)

	attachmentRegex = regexp.MustCompile(`^attachment`)
	inlineRegex     = regexp.MustCompile(`^inline`)
)

// Mime types that can't be inlined. Usually subtypes of main types
var forbiddenInlineTypes = []*regexp.Regexp{svgMimeTypeRegex}

var htmlRenderingTypes = []*regexp.Regexp{xmlTypeRegex, xhtmlTypeRegex}

// Mime types that can be inlined. We can add global types like "image/" or
// specific types like "text/plain". If there is a specific type inside a global
// allowed type that can't be inlined we must add it to the forbiddenInlineTypes var.
// One example of this is the mime type "image". We allow all images to be
// inlined except for SVGs.
var allowedInlineTypes = []*regexp.Regexp{imageTypeRegex, textTypeRegex, videoTypeRegex, pdfTypeRegex}

const (
	svgContentType            = "image/svg+xml"
	textPlainContentType      = "text/plain; charset=utf-8"
	attachmentDispositionText = "attachment"
	inlineDispositionText     = "inline"
	dummyFilename             = "blob"
)

// SafeContentHeaders determines safe content type and disposition for the given data and content disposition
func SafeContentHeaders(data []byte, contentDisposition string) (string, string) {
	detectedContentType := detectContentType(data)

	contentType := safeContentType(detectedContentType)
	contentDisposition = safeContentDisposition(contentType, contentDisposition)

	// Some browsers will render XML inline unless a filename directive is provided with a non-xml file extension
	// This overrides the filename directive in the case of XML data
	if !attachmentRegex.MatchString(contentDisposition) {
		for _, element := range htmlRenderingTypes {
			if isType(detectedContentType, element) {
				disposition, directives, err := mime.ParseMediaType(contentDisposition)
				if err == nil {
					directives["filename"] = dummyFilename
					contentDisposition = mime.FormatMediaType(disposition, directives)
					break
				}
			}
		}
	}

	// Set attachments to application/octet-stream since browsers can do
	// a better job distinguishing certain types (for example: ZIP files
	// vs. Microsoft .docx files). However, browsers may safely render SVGs even
	// when Content-Disposition is an attachment but only if the SVG
	// Content-Type is set. Note that scripts in an SVG file will only be executed
	// if the file is downloaded separately with an inline Content-Disposition.
	if attachmentRegex.MatchString(contentDisposition) && !isType(contentType, svgMimeTypeRegex) {
		contentType = "application/octet-stream"
	}
	return contentType, contentDisposition
}

func detectContentType(data []byte) string {
	// Special case for svg because DetectContentType detects it as text
	if svg.Is(data) {
		return svgContentType
	}

	// Override any existing Content-Type header from other ResponseWriters
	return http.DetectContentType(data)
}

func safeContentType(contentType string) string {
	// http.DetectContentType does not support JavaScript and would only
	// return text/plain. But for cautionary measures, just in case they start supporting
	// it down the road and start returning application/javascript, we want to handle it now
	// to avoid regressions.
	if isType(contentType, javaScriptTypeRegex) {
		return textPlainContentType
	}

	// If the content is text type, we set to plain, because we don't
	// want to render it inline if they're html or javascript
	if isType(contentType, textTypeRegex) {
		return textPlainContentType
	}

	return contentType
}

func safeContentDisposition(contentType string, contentDisposition string) string {
	// If the existing disposition is attachment we return that. This allow us
	// to force a download from GitLab (ie: RawController)
	if attachmentRegex.MatchString(contentDisposition) {
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
		return attachmentDispositionText
	}

	if inlineRegex.MatchString(contentDisposition) {
		return inlineRegex.ReplaceAllString(contentDisposition, attachmentDispositionText)
	}

	return contentDisposition
}

func inlineDisposition(contentDisposition string) string {
	if contentDisposition == "" {
		return inlineDispositionText
	}

	if attachmentRegex.MatchString(contentDisposition) {
		return attachmentRegex.ReplaceAllString(contentDisposition, inlineDispositionText)
	}

	return contentDisposition
}

func isType(contentType string, mimeType *regexp.Regexp) bool {
	return mimeType.MatchString(contentType)
}

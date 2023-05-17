package headers

import (
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func fileContents(fileName string) []byte {
	fileContents, _ := os.ReadFile(fileName)
	return fileContents
}

func TestHeaders(t *testing.T) {
	xmlFileContents := fileContents("../../testdata/test.xml")
	svgFileContents := fileContents("../../testdata/xml.svg")
	xhtmlFileContents := fileContents("../../testdata/index.xhtml")

	tests := []struct {
		desc                       string
		fileContents               []byte
		contentDisposition         string
		expectedContentType        string
		expectedContentDisposition string
	}{
		{
			desc:                       "inline XML file",
			fileContents:               xmlFileContents,
			contentDisposition:         "inline; filename=test.xml",
			expectedContentType:        "text/plain; charset=utf-8",
			expectedContentDisposition: "inline; filename=blob",
		},
		{
			desc:                       "attachment XML file",
			fileContents:               xmlFileContents,
			contentDisposition:         "attachment; filename=test.xml",
			expectedContentType:        "application/octet-stream",
			expectedContentDisposition: "attachment; filename=test.xml",
		},
		{
			desc:                       "inline XHTML file",
			fileContents:               xhtmlFileContents,
			contentDisposition:         "inline; filename=index.xhtml",
			expectedContentType:        "text/plain; charset=utf-8",
			expectedContentDisposition: "inline; filename=blob",
		},
		{
			desc:                       "attachment XHTML file",
			fileContents:               xhtmlFileContents,
			contentDisposition:         "attachment; filename=index.xhtml",
			expectedContentType:        "application/octet-stream",
			expectedContentDisposition: "attachment; filename=index.xhtml",
		},
		{
			desc:                       "svg+xml file",
			fileContents:               svgFileContents,
			contentDisposition:         "",
			expectedContentType:        "image/svg+xml",
			expectedContentDisposition: "attachment",
		},
		{
			desc:                       "svg+xml file",
			fileContents:               svgFileContents,
			contentDisposition:         "inline; filename=xml.svg",
			expectedContentType:        "image/svg+xml",
			expectedContentDisposition: "attachment; filename=xml.svg",
		},
		{
			desc:                       "text file",
			fileContents:               []byte(`a text file`),
			contentDisposition:         "",
			expectedContentType:        "text/plain; charset=utf-8",
			expectedContentDisposition: "inline",
		},
	}

	for _, test := range tests {
		t.Run(test.desc, func(t *testing.T) {
			contentType, newContentDisposition := SafeContentHeaders(test.fileContents, test.contentDisposition)

			require.Equal(t, test.expectedContentType, contentType)
			require.Equal(t, test.expectedContentDisposition, newContentDisposition)
		})
	}
}

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
	tests := []struct {
		desc                       string
		fileContents               []byte
		expectedContentType        string
		expectedContentDisposition string
	}{
		{
			desc:                       "XML file",
			fileContents:               fileContents("../../testdata/test.xml"),
			expectedContentType:        "text/plain; charset=utf-8",
			expectedContentDisposition: "inline; filename=blob",
		},
		{
			desc:                       "XHTML file",
			fileContents:               fileContents("../../testdata/index.xhtml"),
			expectedContentType:        "text/plain; charset=utf-8",
			expectedContentDisposition: "inline; filename=blob",
		},
		{
			desc:                       "svg+xml file",
			fileContents:               fileContents("../../testdata/xml.svg"),
			expectedContentType:        "image/svg+xml",
			expectedContentDisposition: "attachment",
		},
		{
			desc:                       "text file",
			fileContents:               []byte(`a text file`),
			expectedContentType:        "text/plain; charset=utf-8",
			expectedContentDisposition: "inline",
		},
	}

	for _, test := range tests {
		t.Run(test.desc, func(t *testing.T) {
			contentType, newContentDisposition := SafeContentHeaders(test.fileContents, "")

			require.Equal(t, test.expectedContentType, contentType)
			require.Equal(t, test.expectedContentDisposition, newContentDisposition)
		})
	}
}

package parser

import (
	"bytes"
	"fmt"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
)

func createLine(id, label, uri string) []byte {
	return []byte(fmt.Sprintf(`{"id":"%s","label":"%s","uri":"%s"}`+"\n", id, label, uri))
}

func TestParse(t *testing.T) {
	d, err := NewDocs()
	require.NoError(t, err)
	defer d.Close()

	for _, root := range []string{
		"file:///Users/nested",
		"file:///Users/nested/.",
		"file:///Users/nested/",
	} {
		t.Run("Document with root: "+root, func(t *testing.T) {
			data := []byte(`{"id":"1","label":"metaData","projectRoot":"` + root + `"}` + "\n")
			data = append(data, createLine("2", "document", "file:///Users/nested/file.rb")...)
			data = append(data, createLine("3", "document", "file:///Users/nested/folder/file.rb")...)

			require.NoError(t, d.Parse(bytes.NewReader(data)))

			require.Equal(t, "file.rb", d.Entries[2])
			require.Equal(t, "folder/file.rb", d.Entries[3])
		})
	}

	t.Run("Relative path cannot be calculated", func(t *testing.T) {
		originalURI := "file:///Users/nested/folder/file.rb"
		data := []byte(`{"id":"1","label":"metaData","projectRoot":"/a"}` + "\n")
		data = append(data, createLine("2", "document", originalURI)...)

		require.NoError(t, d.Parse(bytes.NewReader(data)))

		require.Equal(t, originalURI, d.Entries[2])
	})
}

func TestParseContainsLine(t *testing.T) {
	d, err := NewDocs()
	require.NoError(t, err)
	defer d.Close()

	data := []byte(`{"id":"5","label":"contains","outV":"1", "inVs": ["2", "3"]}` + "\n")
	data = append(data, []byte(`{"id":"6","label":"contains","outV":"1", "inVs": [4]}`+"\n")...)

	require.NoError(t, d.Parse(bytes.NewReader(data)))

	require.Equal(t, []ID{2, 3, 4}, d.DocRanges[1])
}

func TestParsingVeryLongLine(t *testing.T) {
	d, err := NewDocs()
	require.NoError(t, err)
	defer d.Close()

	line := []byte(`{"id": "` + strings.Repeat("a", 64*1024) + `"}`)

	require.NoError(t, d.Parse(bytes.NewReader(line)))
}

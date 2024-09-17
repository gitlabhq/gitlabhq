package zipartifacts

import (
	"archive/zip"
	"bytes"
	"compress/gzip"
	"context"
	"fmt"
	"io"
	"os"
	"testing"

	"github.com/stretchr/testify/require"
)

func generateTestArchive(w io.Writer) error {
	archive := zip.NewWriter(w)

	// non-POSIX paths are here just to test if we never enter infinite loop
	files := []string{"file1", "some/file/dir/", "some/file/dir/file2", "../../test12/test",
		"/usr/bin/test", `c:\windows\win32.exe`, `c:/windows/win.dll`, "./f/asd", "/"}

	for _, file := range files {
		archiveFile, err := archive.Create(file)
		if err != nil {
			return err
		}

		fmt.Fprint(archiveFile, file)
	}

	return archive.Close()
}

func validateMetadata(r io.Reader) error {
	gz, err := gzip.NewReader(r)
	if err != nil {
		return err
	}

	meta, err := io.ReadAll(gz)
	if err != nil {
		return err
	}

	paths := []string{"file1", "some/", "some/file/", "some/file/dir/", "some/file/dir/file2"}
	for _, path := range paths {
		if !bytes.Contains(meta, []byte(path+"\x00")) {
			return fmt.Errorf("zipartifacts: metadata for path %q not found", path)
		}
	}

	emptyEntry := `{"crc":0,"size":0,"zipped":0}`
	if !bytes.Contains(meta, []byte(emptyEntry)) {
		return fmt.Errorf("zipartifacts: metadata for empty file not found")
	}

	return nil
}

func TestGenerateZipMetadataFromFile(t *testing.T) {
	var metaBuffer bytes.Buffer

	f, err := os.CreateTemp("", "workhorse-metadata.zip-")
	if f != nil {
		defer os.Remove(f.Name())
	}
	require.NoError(t, err)
	defer f.Close()

	err = generateTestArchive(f)
	require.NoError(t, err)
	f.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	archive, err := OpenArchive(ctx, f.Name())
	require.NoError(t, err, "zipartifacts: OpenArchive failed")

	err = GenerateZipMetadata(&metaBuffer, archive)
	require.NoError(t, err, "zipartifacts: GenerateZipMetadata failed")

	err = validateMetadata(&metaBuffer)
	require.NoError(t, err)
}

func TestErrNotAZip(t *testing.T) {
	f, err := os.CreateTemp("", "workhorse-metadata.zip-")
	if f != nil {
		defer os.Remove(f.Name())
	}
	require.NoError(t, err)
	defer f.Close()

	_, err = fmt.Fprint(f, "Not a zip file")
	require.NoError(t, err)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	_, err = OpenArchive(ctx, f.Name())
	require.Equal(t, ErrorCode[CodeNotZip], err, "OpenArchive requires a zip file")
}

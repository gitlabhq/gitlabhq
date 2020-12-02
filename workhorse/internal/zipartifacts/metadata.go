package zipartifacts

import (
	"archive/zip"
	"compress/gzip"
	"encoding/binary"
	"encoding/json"
	"io"
	"path"
	"sort"
	"strconv"
)

type metadata struct {
	Modified int64  `json:"modified,omitempty"`
	Mode     string `json:"mode,omitempty"`
	CRC      uint32 `json:"crc,omitempty"`
	Size     uint64 `json:"size,omitempty"`
	Zipped   uint64 `json:"zipped,omitempty"`
	Comment  string `json:"comment,omitempty"`
}

const MetadataHeaderPrefix = "\x00\x00\x00&" // length of string below, encoded properly
const MetadataHeader = "GitLab Build Artifacts Metadata 0.0.2\n"

func newMetadata(file *zip.File) metadata {
	if file == nil {
		return metadata{}
	}

	return metadata{
		//lint:ignore SA1019 Remove this once the minimum supported version is go 1.10 (go 1.9 and down do not support an alternative)
		Modified: file.ModTime().Unix(),
		Mode:     strconv.FormatUint(uint64(file.Mode().Perm()), 8),
		CRC:      file.CRC32,
		Size:     file.UncompressedSize64,
		Zipped:   file.CompressedSize64,
		Comment:  file.Comment,
	}
}

func (m metadata) writeEncoded(output io.Writer) error {
	j, err := json.Marshal(m)
	if err != nil {
		return err
	}
	j = append(j, byte('\n'))
	return writeBytes(output, j)
}

func writeZipEntryMetadata(output io.Writer, path string, entry *zip.File) error {
	if err := writeString(output, path); err != nil {
		return err
	}

	if err := newMetadata(entry).writeEncoded(output); err != nil {
		return err
	}

	return nil
}

func GenerateZipMetadata(w io.Writer, archive *zip.Reader) error {
	output := gzip.NewWriter(w)
	defer output.Close()

	if err := writeString(output, MetadataHeader); err != nil {
		return err
	}

	// Write empty error header that we may need in the future
	if err := writeString(output, "{}"); err != nil {
		return err
	}

	// Create map of files in zip archive
	zipMap := make(map[string]*zip.File, len(archive.File))

	// Add missing entries
	for _, entry := range archive.File {
		zipMap[entry.Name] = entry

		for d := path.Dir(entry.Name); d != "." && d != "/"; d = path.Dir(d) {
			entryDir := d + "/"
			if _, ok := zipMap[entryDir]; !ok {
				zipMap[entryDir] = nil
			}
		}
	}

	// Sort paths
	sortedPaths := make([]string, 0, len(zipMap))
	for path := range zipMap {
		sortedPaths = append(sortedPaths, path)
	}
	sort.Strings(sortedPaths)

	// Write all files
	for _, path := range sortedPaths {
		if err := writeZipEntryMetadata(output, path, zipMap[path]); err != nil {
			return err
		}
	}
	return nil
}

func writeBytes(output io.Writer, data []byte) error {
	err := binary.Write(output, binary.BigEndian, uint32(len(data)))
	if err == nil {
		_, err = output.Write(data)
	}
	return err
}

func writeString(output io.Writer, str string) error {
	return writeBytes(output, []byte(str))
}

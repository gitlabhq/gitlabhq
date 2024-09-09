package parser

import (
	"archive/zip"
	"bufio"
	"encoding/json"
	"io"
	"path/filepath"
	"strings"
)

const maxScanTokenSize = 1024 * 1024

// Line represents a line in an LSIF document
type Line struct {
	Type string `json:"label"`
}

// Docs represents LSIF documents and related metadata
type Docs struct {
	Root      string
	Entries   map[ID]string
	DocRanges map[ID][]ID
	Ranges    *Ranges
}

// Document represents a single document in an LSIF dump
type Document struct {
	ID  ID     `json:"id"`
	URI string `json:"uri"`
}

// DocumentRange represents a range within a document
type DocumentRange struct {
	OutV     ID   `json:"outV"`
	RangeIDs []ID `json:"inVs"`
}

// Metadata represents metadata in an LSIF dump
type Metadata struct {
	Root string `json:"projectRoot"`
}

// NewDocs creates a new instance of Docs
func NewDocs() (*Docs, error) {
	ranges, err := NewRanges()
	if err != nil {
		return nil, err
	}

	return &Docs{
		Root:      "file:///",
		Entries:   make(map[ID]string),
		DocRanges: make(map[ID][]ID),
		Ranges:    ranges,
	}, nil
}

// Parse reads and processes LSIF data from the provided reader
func (d *Docs) Parse(r io.Reader) error {
	scanner := bufio.NewScanner(r)
	buf := make([]byte, 0, bufio.MaxScanTokenSize)
	scanner.Buffer(buf, maxScanTokenSize)

	for scanner.Scan() {
		if err := d.process(scanner.Bytes()); err != nil {
			return err
		}
	}

	return scanner.Err()
}

func (d *Docs) process(line []byte) error {
	l := Line{}
	if err := json.Unmarshal(line, &l); err != nil {
		return err
	}

	switch l.Type {
	case "metaData":
		if err := d.addMetadata(line); err != nil {
			return err
		}
	case "document":
		if err := d.addDocument(line); err != nil {
			return err
		}
	case "contains":
		if err := d.addDocRanges(line); err != nil {
			return err
		}
	default:
		return d.Ranges.Read(l.Type, line)
	}

	return nil
}

// Close closes the document parser
func (d *Docs) Close() error {
	return d.Ranges.Close()
}

// SerializeEntries serializes document entries to a zip writer
func (d *Docs) SerializeEntries(w *zip.Writer) error {
	for id, path := range d.Entries {
		filePath := Lsif + "/" + path + ".json"

		f, err := w.Create(filePath)
		if err != nil {
			return err
		}

		if err := d.Ranges.Serialize(f, d.DocRanges[id], d.Entries); err != nil {
			return err
		}
	}

	return nil
}

func (d *Docs) addMetadata(line []byte) error {
	var metadata Metadata
	if err := json.Unmarshal(line, &metadata); err != nil {
		return err
	}

	d.Root = strings.TrimSpace(metadata.Root)

	return nil
}

func (d *Docs) addDocument(line []byte) error {
	var doc Document
	if err := json.Unmarshal(line, &doc); err != nil {
		return err
	}

	relativePath, err := filepath.Rel(d.Root, doc.URI)
	if err != nil {
		relativePath = doc.URI
	}

	d.Entries[doc.ID] = relativePath

	return nil
}

func (d *Docs) addDocRanges(line []byte) error {
	var docRange DocumentRange
	if err := json.Unmarshal(line, &docRange); err != nil {
		return err
	}

	d.DocRanges[docRange.OutV] = append(d.DocRanges[docRange.OutV], docRange.RangeIDs...)

	return nil
}

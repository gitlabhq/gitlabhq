package parser

import (
	"archive/zip"
	"bufio"
	"encoding/json"
	"io"
	"strings"
)

const maxScanTokenSize = 1024 * 1024

type Line struct {
	Type string `json:"label"`
}

type Docs struct {
	Root      string
	Entries   map[Id]string
	DocRanges map[Id][]Id
	Ranges    *Ranges
}

type Document struct {
	Id  Id     `json:"id"`
	Uri string `json:"uri"`
}

type DocumentRange struct {
	OutV     Id   `json:"outV"`
	RangeIds []Id `json:"inVs"`
}

type Metadata struct {
	Root string `json:"projectRoot"`
}

func NewDocs(config Config) (*Docs, error) {
	ranges, err := NewRanges(config)
	if err != nil {
		return nil, err
	}

	return &Docs{
		Root:      "file:///",
		Entries:   make(map[Id]string),
		DocRanges: make(map[Id][]Id),
		Ranges:    ranges,
	}, nil
}

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

func (d *Docs) Close() error {
	return d.Ranges.Close()
}

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

	d.Root = strings.TrimSpace(metadata.Root) + "/"

	return nil
}

func (d *Docs) addDocument(line []byte) error {
	var doc Document
	if err := json.Unmarshal(line, &doc); err != nil {
		return err
	}

	d.Entries[doc.Id] = strings.TrimPrefix(doc.Uri, d.Root)

	return nil
}

func (d *Docs) addDocRanges(line []byte) error {
	var docRange DocumentRange
	if err := json.Unmarshal(line, &docRange); err != nil {
		return err
	}

	d.DocRanges[docRange.OutV] = append(d.DocRanges[docRange.OutV], docRange.RangeIds...)

	return nil
}

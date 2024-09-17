// Package parser provides functionality for parsing and processing data related to hovers
package parser

import (
	"encoding/json"
	"os"
)

// Offset represents the position offset
type Offset struct {
	At  int32
	Len int32
}

// Hovers represents a collection of hovers
type Hovers struct {
	File          *os.File
	Offsets       *cache
	CurrentOffset int
}

// RawResult represents the raw result
type RawResult struct {
	Contents json.RawMessage `json:"contents"`
}

// RawData represents the raw data
type RawData struct {
	ID     ID        `json:"id"`
	Result RawResult `json:"result"`
}

// HoverRef represents the hover reference
type HoverRef struct {
	ResultSetID ID `json:"outV"`
	HoverID     ID `json:"inV"`
}

// NewHovers creates a new Hovers instance
func NewHovers() (*Hovers, error) {
	file, err := os.CreateTemp("", "hovers")
	if err != nil {
		return nil, err
	}

	if removeErr := os.Remove(file.Name()); removeErr != nil {
		return nil, removeErr
	}

	offsets, err := newCache("hovers-indexes", Offset{})
	if err != nil {
		return nil, err
	}

	return &Hovers{
		File:          file,
		Offsets:       offsets,
		CurrentOffset: 0,
	}, nil
}

// Read reads the data
func (h *Hovers) Read(label string, line []byte) error {
	switch label {
	case "hoverResult":
		if err := h.addData(line); err != nil {
			return err
		}
	case "textDocument/hover":
		if err := h.addHoverRef(line); err != nil {
			return err
		}
	}

	return nil
}

// For gets the data for the given result set ID
func (h *Hovers) For(resultSetID ID) json.RawMessage {
	var offset Offset
	if err := h.Offsets.Entry(resultSetID, &offset); err != nil || offset.Len == 0 {
		return nil
	}

	hover := make([]byte, offset.Len)
	_, err := h.File.ReadAt(hover, int64(offset.At))
	if err != nil {
		return nil
	}

	return json.RawMessage(hover)
}

// Close closes the Hovers instance
func (h *Hovers) Close() error {
	for _, err := range []error{
		h.File.Close(),
		h.Offsets.Close(),
	} {
		if err != nil {
			return err
		}
	}
	return nil
}

func (h *Hovers) addData(line []byte) error {
	var rawData RawData
	if err := json.Unmarshal(line, &rawData); err != nil {
		return err
	}

	codeHovers, err := newCodeHovers(rawData.Result.Contents)
	if err != nil {
		return err
	}

	codeHoversData, err := json.Marshal(codeHovers)
	if err != nil {
		return err
	}

	n, err := h.File.Write(codeHoversData)
	if err != nil {
		return err
	}

	offset := Offset{At: int32(h.CurrentOffset), Len: int32(n)} //nolint:gosec
	h.CurrentOffset += n

	return h.Offsets.SetEntry(rawData.ID, &offset)
}

func (h *Hovers) addHoverRef(line []byte) error {
	var hoverRef HoverRef
	if err := json.Unmarshal(line, &hoverRef); err != nil {
		return err
	}

	var offset Offset
	if err := h.Offsets.Entry(hoverRef.HoverID, &offset); err != nil {
		return err
	}

	return h.Offsets.SetEntry(hoverRef.ResultSetID, &offset)
}

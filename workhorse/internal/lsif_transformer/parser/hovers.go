package parser

import (
	"encoding/json"
	"io/ioutil"
	"os"
)

type Offset struct {
	At  int32
	Len int32
}

type Hovers struct {
	File          *os.File
	Offsets       *cache
	CurrentOffset int
}

type RawResult struct {
	Contents json.RawMessage `json:"contents"`
}

type RawData struct {
	Id     Id        `json:"id"`
	Result RawResult `json:"result"`
}

type HoverRef struct {
	ResultSetId Id `json:"outV"`
	HoverId     Id `json:"inV"`
}

type ResultSetRef struct {
	ResultSetId Id `json:"outV"`
	RefId       Id `json:"inV"`
}

func NewHovers(config Config) (*Hovers, error) {
	tempPath := config.TempPath

	file, err := ioutil.TempFile(tempPath, "hovers")
	if err != nil {
		return nil, err
	}

	if err := os.Remove(file.Name()); err != nil {
		return nil, err
	}

	offsets, err := newCache(tempPath, "hovers-indexes", Offset{})
	if err != nil {
		return nil, err
	}

	return &Hovers{
		File:          file,
		Offsets:       offsets,
		CurrentOffset: 0,
	}, nil
}

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
	case "textDocument/references":
		if err := h.addResultSetRef(line); err != nil {
			return err
		}
	}

	return nil
}

func (h *Hovers) For(refId Id) json.RawMessage {
	var offset Offset
	if err := h.Offsets.Entry(refId, &offset); err != nil || offset.Len == 0 {
		return nil
	}

	hover := make([]byte, offset.Len)
	_, err := h.File.ReadAt(hover, int64(offset.At))
	if err != nil {
		return nil
	}

	return json.RawMessage(hover)
}

func (h *Hovers) Close() error {
	return combineErrors(
		h.File.Close(),
		h.Offsets.Close(),
	)
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

	offset := Offset{At: int32(h.CurrentOffset), Len: int32(n)}
	h.CurrentOffset += n

	return h.Offsets.SetEntry(rawData.Id, &offset)
}

func (h *Hovers) addHoverRef(line []byte) error {
	var hoverRef HoverRef
	if err := json.Unmarshal(line, &hoverRef); err != nil {
		return err
	}

	var offset Offset
	if err := h.Offsets.Entry(hoverRef.HoverId, &offset); err != nil {
		return err
	}

	return h.Offsets.SetEntry(hoverRef.ResultSetId, &offset)
}

func (h *Hovers) addResultSetRef(line []byte) error {
	var ref ResultSetRef
	if err := json.Unmarshal(line, &ref); err != nil {
		return err
	}

	var offset Offset
	if err := h.Offsets.Entry(ref.ResultSetId, &offset); err != nil {
		return nil
	}

	return h.Offsets.SetEntry(ref.RefId, &offset)
}

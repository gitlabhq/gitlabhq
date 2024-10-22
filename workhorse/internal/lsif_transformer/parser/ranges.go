package parser

import (
	"encoding/json"
	"errors"
	"io"
	"strconv"
)

// Ranges represents a collection of range data
type Ranges struct {
	DefRefs    map[ID]Item
	References *References
	ResultSet  *ResultSet
	Cache      *cache
}

// Range represents a raw range with an ID, start, and end
type Range struct {
	ID          ID       `json:"id"`
	Start       Position `json:"start"`
	End         Position `json:"end"`
	ResultSetID ID
}

// Position represents a start or end position of a definition
type Position struct {
	Line      int32 `json:"line"`
	Character int32 `json:"character"`
}

// RawItem represents a raw item
type RawItem struct {
	Property string `json:"property"`
	RefID    ID     `json:"outV"`
	RangeIDs []ID   `json:"inVs"`
	DocID    ID     `json:"document"`
}

// Item represents an item with line and document ID
type Item struct {
	Line  int32
	DocID ID
}

// SerializedRange represents a serialized range
type SerializedRange struct {
	StartLine      int32                 `json:"start_line"`
	StartChar      int32                 `json:"start_char"`
	EndLine        int32                 `json:"end_line"`
	EndChar        int32                 `json:"end_char"`
	DefinitionPath string                `json:"definition_path,omitempty"`
	Hover          json.RawMessage       `json:"hover"`
	References     []SerializedReference `json:"references,omitempty"`
}

// NewRanges creates a new instance of Ranges
func NewRanges() (*Ranges, error) {
	resultSet, err := NewResultSet()
	if err != nil {
		return nil, err
	}

	references, err := NewReferences()
	if err != nil {
		return nil, err
	}

	cache, err := newCache("ranges", Range{})
	if err != nil {
		return nil, err
	}

	return &Ranges{
		DefRefs:    make(map[ID]Item),
		References: references,
		Cache:      cache,
		ResultSet:  resultSet,
	}, nil
}

// Read processes a label and line, adding ranges or items as appropriate
func (r *Ranges) Read(label string, line []byte) error {
	switch label {
	case "range":
		if err := r.addRange(line); err != nil {
			return err
		}
	case "item":
		if err := r.addItem(line); err != nil {
			return err
		}
	default:
		return r.ResultSet.Read(label, line)
	}

	return nil
}

// Serialize serializes the ranges to the provided writer
func (r *Ranges) Serialize(f io.Writer, rangeIDs []ID, docs map[ID]string) error {
	encoder := json.NewEncoder(f)
	n := len(rangeIDs)

	if _, err := f.Write([]byte("[")); err != nil {
		return err
	}

	for i, rangeID := range rangeIDs {
		entry, err := r.getRange(rangeID)
		if err != nil {
			continue
		}

		serializedRange := SerializedRange{
			StartLine:      entry.Start.Line,
			StartChar:      entry.Start.Character,
			EndLine:        entry.End.Line,
			EndChar:        entry.End.Character,
			DefinitionPath: r.definitionPathFor(docs, entry.ResultSetID),
			Hover:          r.ResultSet.Hovers.For(entry.ResultSetID),
			References:     r.References.For(docs, entry.ResultSetID),
		}
		if err := encoder.Encode(serializedRange); err != nil {
			return err
		}
		if i+1 < n {
			if _, err := f.Write([]byte(",")); err != nil {
				return err
			}
		}
	}

	if _, err := f.Write([]byte("]")); err != nil {
		return err
	}

	return nil
}

// Close closes all resources associated with Ranges
func (r *Ranges) Close() error {
	for _, err := range []error{
		r.Cache.Close(),
		r.References.Close(),
		r.ResultSet.Close(),
	} {
		if err != nil {
			return err
		}
	}
	return nil
}

func (r *Ranges) definitionPathFor(docs map[ID]string, refID ID) string {
	defRef, ok := r.DefRefs[refID]
	if !ok {
		return ""
	}

	defPath := docs[defRef.DocID] + "#L" + strconv.Itoa(int(defRef.Line))

	return defPath
}

func (r *Ranges) addRange(line []byte) error {
	var rg Range
	if err := json.Unmarshal(line, &rg); err != nil {
		return err
	}

	return r.Cache.SetEntry(rg.ID, &rg)
}

func (r *Ranges) addItem(line []byte) error {
	var rawItem RawItem
	if err := json.Unmarshal(line, &rawItem); err != nil {
		return err
	}

	if len(rawItem.RangeIDs) == 0 {
		return errors.New("no range IDs")
	}

	resultSetRef, err := r.ResultSet.RefByID(rawItem.RefID)
	if err != nil {
		return nil
	}

	var references []Item
	for _, rangeID := range rawItem.RangeIDs {
		rg, err := r.getRange(rangeID)
		if err != nil {
			break
		}

		rg.ResultSetID = resultSetRef.ID

		if err := r.Cache.SetEntry(rangeID, rg); err != nil {
			return err
		}

		item := Item{
			Line:  rg.Start.Line + 1,
			DocID: rawItem.DocID,
		}

		definitionItem := r.DefRefs[resultSetRef.ID]
		if item == definitionItem {
			continue
		}

		if resultSetRef.IsDefinition() {
			r.DefRefs[resultSetRef.ID] = item
		} else {
			references = append(references, item)
		}
	}

	if err := r.References.Store(resultSetRef.ID, references); err != nil {
		return err
	}

	return nil
}

func (r *Ranges) getRange(rangeID ID) (*Range, error) {
	var rg Range
	if err := r.Cache.Entry(rangeID, &rg); err != nil {
		return nil, err
	}

	return &rg, nil
}

package parser

import (
	"strconv"
)

// ReferencesOffset represents an offset for a reference with an ID and length
type ReferencesOffset struct {
	ID  ID
	Len int32
}

// References is a structure that holds reference items and their offsets
type References struct {
	Items           *cache
	Offsets         *cache
	CurrentOffsetID ID
}

// SerializedReference represents a serialized reference with a file path
type SerializedReference struct {
	Path string `json:"path"`
}

// NewReferences initializes and returns a new References instance
func NewReferences() (*References, error) {
	items, err := newCache("references", Item{})
	if err != nil {
		return nil, err
	}

	offsets, err := newCache("references-offsets", ReferencesOffset{})
	if err != nil {
		return nil, err
	}

	return &References{
		Items:           items,
		Offsets:         offsets,
		CurrentOffsetID: 0,
	}, nil
}

// Store is responsible for keeping track of references that will be used when
// serializing in `For`.
//
// The references are stored in a file to cache them. It is like
// `map[ID][]Item` (where `Id` is `refId`) but relies on caching the array and
// its offset in files for storage to reduce RAM usage. The items can be
// fetched by calling `getItems`.
func (r *References) Store(refID ID, references []Item) error {
	size := len(references)

	if size == 0 {
		return nil
	}

	items := append(r.getItems(refID), references...)
	err := r.Items.SetEntry(r.CurrentOffsetID, items)
	if err != nil {
		return err
	}

	size = len(items)
	_ = r.Offsets.SetEntry(refID, ReferencesOffset{ID: r.CurrentOffsetID, Len: int32(size)}) //nolint:gosec
	r.CurrentOffsetID += ID(size)                                                            //nolint:gosec

	return nil
}

// For retrieves serialized references for a given document map and reference ID
func (r *References) For(docs map[ID]string, refID ID) []SerializedReference {
	references := r.getItems(refID)
	if references == nil {
		return nil
	}

	var serializedReferences []SerializedReference

	for _, reference := range references {
		serializedReference := SerializedReference{
			Path: docs[reference.DocID] + "#L" + strconv.Itoa(int(reference.Line)),
		}

		serializedReferences = append(serializedReferences, serializedReference)
	}

	return serializedReferences
}

// Close closes the reference
func (r *References) Close() error {
	for _, err := range []error{
		r.Items.Close(),
		r.Offsets.Close(),
	} {
		if err != nil {
			return err
		}
	}
	return nil
}

func (r *References) getItems(refID ID) []Item {
	var offset ReferencesOffset
	if err := r.Offsets.Entry(refID, &offset); err != nil || offset.Len == 0 {
		return nil
	}

	items := make([]Item, offset.Len)
	if err := r.Items.Entry(offset.ID, &items); err != nil {
		return nil
	}

	return items
}

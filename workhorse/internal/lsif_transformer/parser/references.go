package parser

import (
	"strconv"
)

type ReferencesOffset struct {
	Id  Id
	Len int32
}

type References struct {
	Items           *cache
	Offsets         *cache
	CurrentOffsetId Id
}

type SerializedReference struct {
	Path string `json:"path"`
}

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
		CurrentOffsetId: 0,
	}, nil
}

// Store is responsible for keeping track of references that will be used when
// serializing in `For`.
//
// The references are stored in a file to cache them. It is like
// `map[Id][]Item` (where `Id` is `refId`) but relies on caching the array and
// its offset in files for storage to reduce RAM usage. The items can be
// fetched by calling `getItems`.
func (r *References) Store(refId Id, references []Item) error {
	size := len(references)

	if size == 0 {
		return nil
	}

	items := append(r.getItems(refId), references...)
	err := r.Items.SetEntry(r.CurrentOffsetId, items)
	if err != nil {
		return err
	}

	size = len(items)
	r.Offsets.SetEntry(refId, ReferencesOffset{Id: r.CurrentOffsetId, Len: int32(size)})
	r.CurrentOffsetId += Id(size)

	return nil
}

func (r *References) For(docs map[Id]string, refId Id) []SerializedReference {
	references := r.getItems(refId)
	if references == nil {
		return nil
	}

	var serializedReferences []SerializedReference

	for _, reference := range references {
		serializedReference := SerializedReference{
			Path: docs[reference.DocId] + "#L" + strconv.Itoa(int(reference.Line)),
		}

		serializedReferences = append(serializedReferences, serializedReference)
	}

	return serializedReferences
}

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

func (r *References) getItems(refId Id) []Item {
	var offset ReferencesOffset
	if err := r.Offsets.Entry(refId, &offset); err != nil || offset.Len == 0 {
		return nil
	}

	items := make([]Item, offset.Len)
	if err := r.Items.Entry(offset.Id, &items); err != nil {
		return nil
	}

	return items
}

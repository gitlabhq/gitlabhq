package parser

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestReferencesStore(t *testing.T) {
	const (
		docID = 1
		refID = 3
	)

	r, err := NewReferences()
	require.NoError(t, err)

	err = r.Store(refID, []Item{{Line: 2, DocID: docID}, {Line: 3, DocID: docID}})
	require.NoError(t, err)

	docs := map[ID]string{docID: "doc.go"}
	serializedReferences := r.For(docs, refID)

	require.Contains(t, serializedReferences, SerializedReference{Path: "doc.go#L2"})
	require.Contains(t, serializedReferences, SerializedReference{Path: "doc.go#L3"})

	require.NoError(t, r.Close())
}

func TestReferencesStoreEmpty(t *testing.T) {
	const refID = 3

	r, err := NewReferences()
	require.NoError(t, err)

	err = r.Store(refID, []Item{})
	require.NoError(t, err)

	docs := map[ID]string{1: "doc.go"}
	serializedReferences := r.For(docs, refID)

	require.Nil(t, serializedReferences)
	require.NoError(t, r.Close())
}

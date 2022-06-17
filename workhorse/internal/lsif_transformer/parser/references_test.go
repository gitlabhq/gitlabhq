package parser

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestReferencesStore(t *testing.T) {
	const (
		docId = 1
		refId = 3
	)

	r, err := NewReferences()
	require.NoError(t, err)

	err = r.Store(refId, []Item{{Line: 2, DocId: docId}, {Line: 3, DocId: docId}})
	require.NoError(t, err)

	docs := map[Id]string{docId: "doc.go"}
	serializedReferences := r.For(docs, refId)

	require.Contains(t, serializedReferences, SerializedReference{Path: "doc.go#L2"})
	require.Contains(t, serializedReferences, SerializedReference{Path: "doc.go#L3"})

	require.NoError(t, r.Close())
}

func TestReferencesStoreEmpty(t *testing.T) {
	const refId = 3

	r, err := NewReferences()
	require.NoError(t, err)

	err = r.Store(refId, []Item{})
	require.NoError(t, err)

	docs := map[Id]string{1: "doc.go"}
	serializedReferences := r.For(docs, refId)

	require.Nil(t, serializedReferences)
	require.NoError(t, r.Close())
}

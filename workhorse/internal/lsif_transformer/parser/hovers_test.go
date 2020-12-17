package parser

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestHoversRead(t *testing.T) {
	h := setupHovers(t)

	var offset Offset
	require.NoError(t, h.Offsets.Entry(2, &offset))
	require.Equal(t, Offset{At: 0, Len: 19}, offset)

	require.Equal(t, `[{"value":"hello"}]`, string(h.For(1)))

	require.NoError(t, h.Close())
}

func setupHovers(t *testing.T) *Hovers {
	h, err := NewHovers(Config{})
	require.NoError(t, err)

	require.NoError(t, h.Read("hoverResult", []byte(`{"id":"2","label":"hoverResult","result":{"contents": ["hello"]}}`)))
	require.NoError(t, h.Read("textDocument/hover", []byte(`{"id":4,"label":"textDocument/hover","outV":"3","inV":2}`)))
	require.NoError(t, h.Read("textDocument/references", []byte(`{"id":"3","label":"textDocument/references","outV":3,"inV":"1"}`)))

	return h
}

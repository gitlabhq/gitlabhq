package parser

import (
	"bytes"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestRangesRead(t *testing.T) {
	r, cleanup := setup(t)
	defer cleanup()

	firstRange := Range{Line: 1, Character: 2, RefId: 4}
	rg, err := r.getRange(1)
	require.NoError(t, err)
	require.Equal(t, &firstRange, rg)

	secondRange := Range{Line: 5, Character: 4, RefId: 4}
	rg, err = r.getRange(2)
	require.NoError(t, err)
	require.Equal(t, &secondRange, rg)

	thirdRange := Range{Line: 7, Character: 4, RefId: 4}
	rg, err = r.getRange(3)
	require.NoError(t, err)
	require.Equal(t, &thirdRange, rg)
}

func TestSerialize(t *testing.T) {
	r, cleanup := setup(t)
	defer cleanup()

	docs := map[Id]string{6: "def-path", 7: "ref-path"}

	var buf bytes.Buffer
	err := r.Serialize(&buf, []Id{1}, docs)
	want := `[{"start_line":1,"start_char":2,"definition_path":"def-path#L2","hover":null,"references":[{"path":"ref-path#L6"},{"path":"ref-path#L8"}]}` + "\n]"

	require.NoError(t, err)
	require.Equal(t, want, buf.String())
}

func setup(t *testing.T) (*Ranges, func()) {
	r, err := NewRanges(Config{})
	require.NoError(t, err)

	require.NoError(t, r.Read("range", []byte(`{"id":1,"label":"range","start":{"line":1,"character":2}}`)))
	require.NoError(t, r.Read("range", []byte(`{"id":"2","label":"range","start":{"line":5,"character":4}}`)))
	require.NoError(t, r.Read("range", []byte(`{"id":"3","label":"range","start":{"line":7,"character":4}}`)))

	require.NoError(t, r.Read("item", []byte(`{"id":5,"label":"item","property":"definitions","outV":"4","inVs":[1],"document":"6"}`)))
	require.NoError(t, r.Read("item", []byte(`{"id":"6","label":"item","property":"references","outV":4,"inVs":["2"],"document":"7"}`)))
	require.NoError(t, r.Read("item", []byte(`{"id":"7","label":"item","property":"references","outV":4,"inVs":["3"],"document":"7"}`)))

	cleanup := func() {
		require.NoError(t, r.Close())
	}

	return r, cleanup
}

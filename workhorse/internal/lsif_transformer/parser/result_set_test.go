package parser

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestResultSetRead(t *testing.T) {
	r := setupResultSet(t)

	var ref ResultSetRef
	require.NoError(t, r.Cache.Entry(2, &ref))
	require.Equal(t, ResultSetRef{ID: 1, Property: ReferencesProp}, ref)
	require.False(t, ref.IsDefinition())

	require.NoError(t, r.Cache.Entry(4, &ref))
	require.Equal(t, ResultSetRef{ID: 3, Property: DefinitionProp}, ref)
	require.True(t, ref.IsDefinition())

	require.NoError(t, r.Close())
}

func TestResultSetRefById(t *testing.T) {
	r := setupResultSet(t)

	ref, err := r.RefByID(2)
	require.NoError(t, err)
	require.Equal(t, &ResultSetRef{ID: 1, Property: ReferencesProp}, ref)
	require.False(t, ref.IsDefinition())

	ref, err = r.RefByID(4)
	require.NoError(t, err)
	require.Equal(t, &ResultSetRef{ID: 3, Property: DefinitionProp}, ref)
	require.True(t, ref.IsDefinition())

	require.NoError(t, r.Close())
}

func setupResultSet(t *testing.T) *ResultSet {
	r, err := NewResultSet()
	require.NoError(t, err)

	require.NoError(t, r.Read("textDocument/references", []byte(`{"id":4,"label":"textDocument/references","outV":"1","inV":2}`)))
	require.NoError(t, r.Read("textDocument/definition", []byte(`{"id":5,"label":"textDocument/definition","outV":"3","inV":4}`)))

	return r
}

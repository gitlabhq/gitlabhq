package parser

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/require"
)

type jsonWithID struct {
	Value ID `json:"value"`
}

func TestId(t *testing.T) {
	var v jsonWithID
	require.NoError(t, json.Unmarshal([]byte(`{ "value": 1230 }`), &v))
	require.Equal(t, ID(1230), v.Value)

	require.NoError(t, json.Unmarshal([]byte(`{ "value": "1230" }`), &v))
	require.Equal(t, ID(1230), v.Value)

	require.Error(t, json.Unmarshal([]byte(`{ "value": "1.5" }`), &v))
	require.Error(t, json.Unmarshal([]byte(`{ "value": 1.5 }`), &v))
	require.Error(t, json.Unmarshal([]byte(`{ "value": "-1" }`), &v))
	require.Error(t, json.Unmarshal([]byte(`{ "value": -1 }`), &v))
	require.Error(t, json.Unmarshal([]byte(`{ "value": 21000000 }`), &v))
	require.Error(t, json.Unmarshal([]byte(`{ "value": "21000000" }`), &v))
}

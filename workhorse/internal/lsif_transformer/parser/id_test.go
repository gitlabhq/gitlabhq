package parser

import (
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/require"
)

type jsonWithId struct {
	Value Id `json:"value"`
}

func TestId(t *testing.T) {
	var v jsonWithId
	require.NoError(t, json.Unmarshal([]byte(`{ "value": 1230 }`), &v))
	require.Equal(t, Id(1230), v.Value)

	require.NoError(t, json.Unmarshal([]byte(`{ "value": "1230" }`), &v))
	require.Equal(t, Id(1230), v.Value)

	require.Error(t, json.Unmarshal([]byte(`{ "value": "1.5" }`), &v))
	require.Error(t, json.Unmarshal([]byte(`{ "value": 1.5 }`), &v))
	require.Error(t, json.Unmarshal([]byte(`{ "value": "-1" }`), &v))
	require.Error(t, json.Unmarshal([]byte(`{ "value": -1 }`), &v))
	require.Error(t, json.Unmarshal([]byte(`{ "value": 21000000 }`), &v))
	require.Error(t, json.Unmarshal([]byte(`{ "value": "21000000" }`), &v))
}

package senddata

import (
	"encoding/base64"
	"encoding/json"
	"testing"

	"github.com/stretchr/testify/require"
)

const testPrefix = "test:"

func TestPrefixMatch(t *testing.T) {
	tests := []struct {
		name          string
		input         string
		expectedMatch bool
	}{
		{"Match with correct prefix", "test:sendData", true},
		{"Match with correct prefix and nested data", "test:otherData:nestedData", true},
		{"Does not match with wrong prefix", "another:sendData", false},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := require.New(t)
			prefix := Prefix(testPrefix)
			name := prefix.Name()

			r.Contains(testPrefix, name)
			r.Equal(tt.expectedMatch, prefix.Match(tt.input))
		})
	}
}

func TestPrefixUnpack(t *testing.T) {
	tests := []struct {
		name           string
		inputData      string
		expectedResult string
	}{
		{"Valid JSON data encoded with base64", "test data", "test data"},
		{"Invalid base64 encoded data", "invalid_base64_encoded_data", "invalid_base64_encoded_data"},
		{"Invalid JSON data encoded with base64", base64.URLEncoding.EncodeToString([]byte("invalid_json")), "aW52YWxpZF9qc29u"},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			r := require.New(t)
			jsonBytes, err := json.Marshal(tt.inputData)
			r.NoError(err)
			sendData := base64.URLEncoding.EncodeToString(jsonBytes)

			prefix := Prefix(testPrefix)

			var result string
			err = prefix.Unpack(&result, testPrefix+sendData)
			r.NoError(err)
			r.Equal(tt.expectedResult, result)
		})
	}
}

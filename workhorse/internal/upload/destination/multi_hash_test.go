package destination

import (
	"sort"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestNewMultiHash(t *testing.T) {
	tests := []struct {
		name           string
		allowedHashes  []string
		expectedHashes []string
	}{
		{
			name:           "default",
			allowedHashes:  nil,
			expectedHashes: []string{"md5", "sha1", "sha256", "sha512"},
		},
		{
			name:           "blank",
			allowedHashes:  []string{},
			expectedHashes: []string{"md5", "sha1", "sha256", "sha512"},
		},
		{
			name:           "no MD5",
			allowedHashes:  []string{"sha1", "sha256", "sha512"},
			expectedHashes: []string{"sha1", "sha256", "sha512"},
		},

		{
			name:           "unlisted hash",
			allowedHashes:  []string{"sha1", "sha256", "sha512", "sha3-256"},
			expectedHashes: []string{"sha1", "sha256", "sha512"},
		},
	}

	for _, test := range tests {
		mh := newMultiHash(test.allowedHashes)

		require.Equal(t, len(test.expectedHashes), len(mh.hashes))

		var keys []string
		for key := range mh.hashes {
			keys = append(keys, key)
		}

		sort.Strings(keys)
		require.Equal(t, test.expectedHashes, keys)
	}
}

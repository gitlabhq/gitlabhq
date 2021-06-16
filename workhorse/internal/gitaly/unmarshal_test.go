package gitaly

import (
	"testing"

	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"
)

func TestUnmarshalJSON(t *testing.T) {
	testCases := []struct {
		desc string
		in   string
		out  gitalypb.Repository
	}{
		{
			desc: "basic example",
			in:   `{"relative_path":"foo/bar.git"}`,
			out:  gitalypb.Repository{RelativePath: "foo/bar.git"},
		},
		{
			desc: "unknown field",
			in:   `{"relative_path":"foo/bar.git","unknown_field":12345}`,
			out:  gitalypb.Repository{RelativePath: "foo/bar.git"},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			result := gitalypb.Repository{}
			require.NoError(t, UnmarshalJSON(tc.in, &result))
			require.Equal(t, tc.out, result)
		})
	}
}

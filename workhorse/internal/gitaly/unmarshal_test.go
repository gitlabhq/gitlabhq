package gitaly

import (
	"testing"

	"github.com/golang/protobuf/proto" //lint:ignore SA1019 https://gitlab.com/gitlab-org/gitlab/-/issues/324868
	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/gitaly/v15/proto/go/gitalypb"
)

func TestUnmarshalJSON(t *testing.T) {
	testCases := []struct {
		desc string
		in   string
		out  *gitalypb.Repository
	}{
		{
			desc: "basic example",
			in:   `{"relative_path":"foo/bar.git"}`,
			out:  &gitalypb.Repository{RelativePath: "foo/bar.git"},
		},
		{
			desc: "unknown field",
			in:   `{"relative_path":"foo/bar.git","unknown_field":12345}`,
			out:  &gitalypb.Repository{RelativePath: "foo/bar.git"},
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			result := &gitalypb.Repository{}
			require.NoError(t, UnmarshalJSON(tc.in, result))
			require.True(t, proto.Equal(tc.out, result))
		})
	}
}

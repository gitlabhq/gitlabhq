package git

import (
	"bytes"
	"fmt"
	"io"
	"testing"

	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/anypb"
	"google.golang.org/protobuf/types/known/durationpb"
)

func TestHandleLimitErr(t *testing.T) {
	testCases := []struct {
		desc          string
		errWriter     func(io.Writer) error
		expectedBytes []byte
	}{
		{
			desc:      "upload pack",
			errWriter: writeUploadPackError,
			expectedBytes: bytes.Join([][]byte{
				[]byte{'0', '0', '4', '7'},
				[]byte("ERR GitLab is currently unable to handle this request due to load.\n"),
			}, []byte{}),
		},
		{
			desc:      "receive pack",
			errWriter: writeReceivePackError,
			expectedBytes: bytes.Join([][]byte{
				{'0', '0', '2', '3', 1, '0', '0', '1', 'a'},
				[]byte("unpack server is busy\n"),
				{'0', '0', '0', '0', '0', '0', '4', '4', 2},
				[]byte("GitLab is currently unable to handle this request due to load.\n"),
				{'0', '0', '0', '0'},
			}, []byte{}),
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			var body bytes.Buffer
			err := errWithDetail(t, &gitalypb.LimitError{
				ErrorMessage: "concurrency queue wait time reached",
				RetryAfter:   durationpb.New(0)})

			handleLimitErr(fmt.Errorf("wrapped error: %w", err), &body, tc.errWriter)
			require.Equal(t, tc.expectedBytes, body.Bytes())
		})
	}

	t.Run("non LimitError", func(t *testing.T) {
		var body bytes.Buffer
		err := status.Error(codes.Internal, "some internal error")
		handleLimitErr(fmt.Errorf("wrapped error: %w", err), &body, writeUploadPackError)
		require.Equal(t, []byte(nil), body.Bytes())

		handleLimitErr(fmt.Errorf("wrapped error: %w", err), &body, writeReceivePackError)
		require.Equal(t, []byte(nil), body.Bytes())

	})
}

// errWithDetail adds the given details to the error if it is a gRPC status whose code is not OK.
func errWithDetail(t *testing.T, detail proto.Message) error {
	st := status.New(codes.Unavailable, "too busy")

	proto := st.Proto()
	marshaled, err := anypb.New(detail)
	require.NoError(t, err)

	proto.Details = append(proto.Details, marshaled)

	return status.ErrorProto(proto)
}

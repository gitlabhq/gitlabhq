package git

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"testing"

	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"
	"gitlab.com/gitlab-org/labkit/correlation"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"
	"google.golang.org/protobuf/types/known/anypb"
	"google.golang.org/protobuf/types/known/durationpb"
)

func TestHandleLimitErr(t *testing.T) {
	const expectedCorrelationID = "abcdef01234"

	testCases := []struct {
		desc          string
		errWriter     func(io.Writer, string) error
		expectedBytes []byte
	}{
		{
			desc:      "upload pack",
			errWriter: writeUploadPackError,
			expectedBytes: bytes.Join([][]byte{
				{'0', '0', '5', '8'},
				[]byte("ERR GitLab is currently unable to handle this request due to load (ID abcdef01234).\n"),
			}, []byte{}),
		},
		{
			desc:      "receive pack",
			errWriter: writeReceivePackError,
			expectedBytes: bytes.Join([][]byte{
				{'0', '0', '2', '3', 1, '0', '0', '1', 'a'},
				[]byte("unpack server is busy\n"),
				{'0', '0', '0', '0', '0', '0', '5', '5', 2},
				[]byte("GitLab is currently unable to handle this request due to load (ID abcdef01234).\n"),
				{'0', '0', '0', '0'},
			}, []byte{}),
		},
	}

	ctx := correlation.ContextWithCorrelation(context.Background(), expectedCorrelationID)

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			var body bytes.Buffer
			err := errWithDetail(t, &gitalypb.LimitError{
				ErrorMessage: "concurrency queue wait time reached",
				RetryAfter:   durationpb.New(0)})

			handleLimitErr(fmt.Errorf("wrapped error: %w", err), &body, ctx, tc.errWriter)
			require.Equal(t, tc.expectedBytes, body.Bytes())
		})
	}

	t.Run("non LimitError", func(t *testing.T) {
		var body bytes.Buffer
		err := status.Error(codes.Internal, "some internal error")
		handleLimitErr(fmt.Errorf("wrapped error: %w", err), &body, ctx, writeUploadPackError)
		require.Equal(t, []byte(nil), body.Bytes(), expectedCorrelationID)

		handleLimitErr(fmt.Errorf("wrapped error: %w", err), &body, ctx, writeReceivePackError)
		require.Equal(t, []byte(nil), body.Bytes(), expectedCorrelationID)
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

package git

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"io"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"
)

func TestListBlobsHTTPPreservesSizeAndChunks(test *testing.T) {
	const bytesLimit = 1024 * 1024
	for _, size := range []int{0, bytesLimit - 1, bytesLimit, bytesLimit + 1} {
		test.Run(fmt.Sprint(size), func(test *testing.T) {
			data := bytes.Repeat([]byte{0xff}, min(size, bytesLimit))
			chunks := []*gitalypb.ListBlobsResponse{
				{Blobs: []*gitalypb.ListBlobsResponse_Blob{{Oid: "blob", Size: int64(size), Data: data[:len(data)/2]}}},
				{Blobs: []*gitalypb.ListBlobsResponse_Blob{{Data: data[len(data)/2:]}}},
			}
			address := startGRPCServer(test, func(server *grpc.Server) {
				gitalypb.RegisterBlobServiceServer(server, &mockBlobServer{
					listBlobsFunc: func(request *gitalypb.ListBlobsRequest, stream gitalypb.BlobService_ListBlobsServer) error {
						assert.EqualValues(test, bytesLimit, request.GetBytesLimit())
						assert.Equal(test, []string{"blob"}, request.GetRevisions())
						for _, chunk := range chunks {
							if err := stream.Send(chunk); err != nil {
								return err
							}
						}
						return nil
					},
				})
			})
			response := requestRepositoryStream(test, SendListBlobs, address, &gitalypb.ListBlobsRequest{
				Repository: &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
				Revisions:  []string{"blob"}, BytesLimit: bytesLimit,
			})
			defer response.Body.Close()
			require.Equal(test, http.StatusOK, response.StatusCode)
			require.Equal(test, "application/octet-stream", response.Header.Get("Content-Type"))
			for _, expected := range chunks {
				var length uint32
				require.NoError(test, binary.Read(response.Body, binary.BigEndian, &length))
				frame := make([]byte, length)
				_, err := io.ReadFull(response.Body, frame)
				require.NoError(test, err)
				var decoded gitalypb.ListBlobsResponse
				require.NoError(test, proto.Unmarshal(frame, &decoded))
				require.True(test, proto.Equal(expected, &decoded), "blob content and original size must survive framing")
			}
			remaining, err := io.ReadAll(response.Body)
			require.NoError(test, err)
			require.Empty(test, remaining)
		})
	}
}

func TestListBlobsHTTPTellsMissingObjectsApartFromOutages(test *testing.T) {
	const missingObjectMessage = `processing blobs: rev-list pipeline command: exit status 128, stderr: "fatal: bad object missing"`
	for _, testCase := range []struct {
		name           string
		gitalyError    error
		expectedStatus int
		expectedBody   string
	}{
		{"missing object", status.Error(codes.Internal, missingObjectMessage), http.StatusNotFound, missingObjectMessage + "\n"},
		{"outage", status.Error(codes.Unavailable, "gitaly is restarting"), http.StatusInternalServerError, "Internal Server Error\n"},
	} {
		test.Run(testCase.name, func(test *testing.T) {
			address := startGRPCServer(test, func(server *grpc.Server) {
				gitalypb.RegisterBlobServiceServer(server, &mockBlobServer{
					listBlobsFunc: func(_ *gitalypb.ListBlobsRequest, _ gitalypb.BlobService_ListBlobsServer) error {
						return testCase.gitalyError
					},
				})
			})
			response := requestRepositoryStream(test, SendListBlobs, address, &gitalypb.ListBlobsRequest{Revisions: []string{"missing"}})
			defer response.Body.Close()
			require.Equal(test, testCase.expectedStatus, response.StatusCode)
			body, err := io.ReadAll(response.Body)
			require.NoError(test, err)
			require.Equal(test, testCase.expectedBody, string(body))
		})
	}
}

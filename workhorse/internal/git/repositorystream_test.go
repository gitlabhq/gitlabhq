package git

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/headers"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func requestRepositoryStream(test *testing.T, injector senddata.Injecter, address string, message proto.Message, responseWrappers ...func(http.ResponseWriter) http.ResponseWriter) *http.Response {
	test.Helper()

	messageJSON, err := protojson.Marshal(message)
	require.NoError(test, err)
	payload := encodeSendData(test, injector.Name()+":", map[string]interface{}{
		"GitalyServer": api.GitalyServer{Address: address},
		string(message.ProtoReflect().Descriptor().Name()): string(messageJSON),
	})
	backend := http.HandlerFunc(func(response http.ResponseWriter, _ *http.Request) {
		response.Header().Set(headers.GitlabWorkhorseSendDataHeader, payload)
		response.WriteHeader(http.StatusOK)
	})
	handler := senddata.SendData(backend, injector)
	server := httptest.NewServer(http.HandlerFunc(func(response http.ResponseWriter, request *http.Request) {
		for _, wrap := range responseWrappers {
			response = wrap(response)
		}
		handler.ServeHTTP(response, request)
	}))
	test.Cleanup(server.Close)
	client := &http.Client{Timeout: 5 * time.Second}
	response, err := client.Post(server.URL, "application/json", nil)
	require.NoError(test, err)
	require.Empty(test, response.Header.Get(headers.GitlabWorkhorseSendDataHeader))
	return response
}

type failingRepositoryResponse struct {
	http.ResponseWriter
	writeFailureAt int
	flushFailureAt int
	writes         int
	flushes        int
}

func (response *failingRepositoryResponse) Write(data []byte) (int, error) {
	response.writes++
	if response.writes == response.writeFailureAt {
		return 0, io.ErrClosedPipe
	}
	return response.ResponseWriter.Write(data)
}

func (response *failingRepositoryResponse) FlushError() error {
	response.flushes++
	if response.flushes == response.flushFailureAt {
		return io.ErrClosedPipe
	}
	return http.NewResponseController(response.ResponseWriter).Flush()
}

func TestRepositoryStreamsAbortResponseWriteFailures(test *testing.T) {
	repository := &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"}
	for _, scenario := range []struct {
		name           string
		injector       senddata.Injecter
		request        proto.Message
		writeFailureAt int
		flushFailureAt int
	}{
		{"changed path encoding", SendChangedPaths, &gitalypb.FindChangedPathsRequest{Repository: repository}, 2, 0},
		{"changed path flush", SendChangedPaths, &gitalypb.FindChangedPathsRequest{Repository: repository}, 0, 2},
		{"blob frame length", SendListBlobs, &gitalypb.ListBlobsRequest{Repository: repository}, 3, 0},
		{"blob frame body", SendListBlobs, &gitalypb.ListBlobsRequest{Repository: repository}, 4, 0},
		{"blob frame flush", SendListBlobs, &gitalypb.ListBlobsRequest{Repository: repository}, 0, 2},
	} {
		test.Run(scenario.name, func(test *testing.T) {
			address := startGRPCServer(test, func(server *grpc.Server) {
				gitalypb.RegisterDiffServiceServer(server, &mockDiffServiceServer{
					findChangedPathsFunc: func(_ *gitalypb.FindChangedPathsRequest, stream gitalypb.DiffService_FindChangedPathsServer) error {
						message := &gitalypb.FindChangedPathsResponse{Paths: []*gitalypb.ChangedPaths{{Path: []byte("file")}}}
						if err := stream.Send(message); err != nil {
							return err
						}
						return stream.Send(message)
					},
				})
				gitalypb.RegisterBlobServiceServer(server, &mockBlobServer{
					listBlobsFunc: func(_ *gitalypb.ListBlobsRequest, stream gitalypb.BlobService_ListBlobsServer) error {
						message := &gitalypb.ListBlobsResponse{Blobs: []*gitalypb.ListBlobsResponse_Blob{{Oid: "blob", Data: []byte("data")}}}
						if err := stream.Send(message); err != nil {
							return err
						}
						return stream.Send(message)
					},
				})
			})
			response := requestRepositoryStream(test, scenario.injector, address, scenario.request, func(writer http.ResponseWriter) http.ResponseWriter {
				return &failingRepositoryResponse{
					ResponseWriter: writer,
					writeFailureAt: scenario.writeFailureAt,
					flushFailureAt: scenario.flushFailureAt,
				}
			})
			defer response.Body.Close()
			body, err := io.ReadAll(response.Body)
			require.Equal(test, http.StatusOK, response.StatusCode)
			require.NotEmpty(test, body)
			require.ErrorIs(test, err, io.ErrUnexpectedEOF)
		})
	}
}

func TestRepositoryStreamsRejectFailures(test *testing.T) {
	for _, scenario := range []struct {
		name       string
		repository *gitalypb.Repository
	}{
		{name: "before sending data", repository: &gitalypb.Repository{}},
		{name: "after sending data", repository: &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"}},
	} {
		for _, stream := range []struct {
			injector senddata.Injecter
			request  proto.Message
		}{
			{SendChangedPaths, &gitalypb.FindChangedPathsRequest{Repository: scenario.repository}},
			{SendListBlobs, &gitalypb.ListBlobsRequest{Repository: scenario.repository, Revisions: []string{"missing"}}},
		} {
			test.Run(stream.injector.Name()+"/"+scenario.name, func(test *testing.T) {
				address := startGRPCServer(test, func(server *grpc.Server) {
					backend := testhelper.NewGitalyServer(codes.Unavailable)
					gitalypb.RegisterDiffServiceServer(server, backend)
					gitalypb.RegisterBlobServiceServer(server, backend)
				})
				response := requestRepositoryStream(test, stream.injector, address, stream.request)
				defer response.Body.Close()
				body, err := io.ReadAll(response.Body)
				if scenario.repository.GetStorageName() == "" {
					require.NoError(test, err)
					require.Equal(test, http.StatusInternalServerError, response.StatusCode)
					require.Equal(test, "Internal Server Error\n", string(body))
					require.Contains(test, response.Header.Get("Content-Type"), "text/plain")
				} else {
					require.Equal(test, http.StatusOK, response.StatusCode)
					require.ErrorIs(test, err, io.ErrUnexpectedEOF)
				}
			})
		}
	}
}

func TestRepositoryStreamsCancelGitaly(test *testing.T) {
	repository := &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"}
	for _, stream := range []struct {
		injector senddata.Injecter
		request  proto.Message
	}{
		{SendChangedPaths, &gitalypb.FindChangedPathsRequest{Repository: repository}},
		{SendListBlobs, &gitalypb.ListBlobsRequest{Repository: repository, Revisions: []string{"blob"}}},
	} {
		test.Run(stream.injector.Name(), func(test *testing.T) {
			canceled := make(chan struct{})
			waitForCancellation := func(ctx context.Context, send func() error) error {
				if err := send(); err != nil {
					return err
				}
				<-ctx.Done()
				close(canceled)
				return ctx.Err()
			}
			address := startGRPCServer(test, func(server *grpc.Server) {
				gitalypb.RegisterDiffServiceServer(server, &mockDiffServiceServer{
					findChangedPathsFunc: func(_ *gitalypb.FindChangedPathsRequest, response gitalypb.DiffService_FindChangedPathsServer) error {
						return waitForCancellation(response.Context(), func() error {
							return response.Send(&gitalypb.FindChangedPathsResponse{Paths: []*gitalypb.ChangedPaths{{Path: []byte("file")}}})
						})
					},
				})
				gitalypb.RegisterBlobServiceServer(server, &mockBlobServer{
					listBlobsFunc: func(_ *gitalypb.ListBlobsRequest, response gitalypb.BlobService_ListBlobsServer) error {
						return waitForCancellation(response.Context(), func() error {
							return response.Send(&gitalypb.ListBlobsResponse{Blobs: []*gitalypb.ListBlobsResponse_Blob{{Oid: "blob", Data: []byte("data")}}})
						})
					},
				})
			})
			response := requestRepositoryStream(test, stream.injector, address, stream.request)
			defer response.Body.Close()
			_, err := io.ReadFull(response.Body, make([]byte, 1))
			require.NoError(test, err)
			require.NoError(test, response.Body.Close())
			select {
			case <-canceled:
			case <-time.After(5 * time.Second):
				test.Fatal("Gitaly request continued after the HTTP client disconnected")
			}
		})
	}
}

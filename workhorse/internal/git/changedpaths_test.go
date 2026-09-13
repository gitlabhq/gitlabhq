package git

import (
	"encoding/json"
	"io"
	"net/http"
	"sync/atomic"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func TestChangedPathsBatchHTTP(test *testing.T) {
	request := &gitalypb.FindChangedPathsRequest{
		Repository: &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
		Requests: []*gitalypb.FindChangedPathsRequest_Request{
			{Type: &gitalypb.FindChangedPathsRequest_Request_CommitRequest_{CommitRequest: &gitalypb.FindChangedPathsRequest_Request_CommitRequest{
				CommitRevision: "target", ParentCommitRevisions: []string{"base"},
			}}},
			{Type: &gitalypb.FindChangedPathsRequest_Request_CommitRequest_{CommitRequest: &gitalypb.FindChangedPathsRequest_Request_CommitRequest{
				CommitRevision: "unchanged", ParentCommitRevisions: []string{"unchanged"},
			}}},
			{Type: &gitalypb.FindChangedPathsRequest_Request_CommitRequest_{CommitRequest: &gitalypb.FindChangedPathsRequest_Request_CommitRequest{
				CommitRevision: "other", ParentCommitRevisions: []string{"target"},
			}}},
		},
	}
	var calls atomic.Int32
	address := startGRPCServer(test, func(server *grpc.Server) {
		gitalypb.RegisterDiffServiceServer(server, &mockDiffServiceServer{
			findChangedPathsFunc: func(received *gitalypb.FindChangedPathsRequest, stream gitalypb.DiffService_FindChangedPathsServer) error {
				calls.Add(1)
				assert.True(test, proto.Equal(request, received), "forward the complete batch unchanged")
				for _, change := range []*gitalypb.ChangedPaths{
					{CommitId: "target", Path: []byte("new.txt"), Status: gitalypb.ChangedPaths_ADDED, NewBlobId: "new", NewMode: 0o100644},
					{CommitId: "other", Path: []byte("second.txt"), Status: gitalypb.ChangedPaths_MODIFIED, OldBlobId: "before", NewBlobId: "after", OldMode: 0o100644, NewMode: 0o100644},
					{CommitId: "target", Path: []byte("removed.txt"), Status: gitalypb.ChangedPaths_DELETED, OldBlobId: "old", OldMode: 0o100644},
					{CommitId: "target", Path: []byte("renamed.txt"), OldPath: []byte("original.txt"), Status: gitalypb.ChangedPaths_RENAMED, OldBlobId: "old", NewBlobId: "new", OldMode: 0o100644, NewMode: 0o100644},
					{CommitId: "target", Path: []byte("vendored"), Status: gitalypb.ChangedPaths_DELETED, OldBlobId: "submodule", OldMode: 0o160000},
					{CommitId: "target", Path: []byte("link"), Status: gitalypb.ChangedPaths_TYPE_CHANGE, OldMode: 0o100644, NewMode: 0o120000},
				} {
					if err := stream.Send(&gitalypb.FindChangedPathsResponse{Paths: []*gitalypb.ChangedPaths{change}}); err != nil {
						return err
					}
				}
				return nil
			},
		})
	})
	response := requestRepositoryStream(test, SendChangedPaths, address, request)
	defer response.Body.Close()
	require.Equal(test, http.StatusOK, response.StatusCode)
	require.Equal(test, "application/x-ndjson", response.Header.Get("Content-Type"))
	decoder := json.NewDecoder(response.Body)
	var rows []map[string]interface{}
	for {
		var row map[string]interface{}
		err := decoder.Decode(&row)
		if err == io.EOF {
			break
		}
		require.NoError(test, err)
		rows = append(rows, row)
	}
	require.Equal(test, []map[string]interface{}{
		{"commit_id": "target", "path": "new.txt", "status": "ADDED", "old_path": "", "old_mode": float64(0), "new_mode": float64(0o100644), "old_blob_id": "", "new_blob_id": "new"},
		{"commit_id": "other", "path": "second.txt", "status": "MODIFIED", "old_path": "", "old_mode": float64(0o100644), "new_mode": float64(0o100644), "old_blob_id": "before", "new_blob_id": "after"},
		{"commit_id": "target", "path": "removed.txt", "status": "DELETED", "old_path": "", "old_mode": float64(0o100644), "new_mode": float64(0), "old_blob_id": "old", "new_blob_id": ""},
		{"commit_id": "target", "path": "renamed.txt", "status": "RENAMED", "old_path": "original.txt", "old_mode": float64(0o100644), "new_mode": float64(0o100644), "old_blob_id": "old", "new_blob_id": "new"},
		{"commit_id": "target", "path": "vendored", "status": "DELETED", "old_path": "", "old_mode": float64(0o160000), "new_mode": float64(0), "old_blob_id": "submodule", "new_blob_id": ""},
		{"commit_id": "target", "path": "link", "status": "TYPE_CHANGE", "old_path": "", "old_mode": float64(0o100644), "new_mode": float64(0o120000), "old_blob_id": "", "new_blob_id": ""},
	}, rows)
	require.EqualValues(test, 1, calls.Load())
}

func TestChangedPathsTreeHTTPPreservesLegacyShape(test *testing.T) {
	address := startGRPCServer(test, func(server *grpc.Server) {
		gitalypb.RegisterDiffServiceServer(server, testhelper.NewGitalyServer(codes.OK))
	})
	response := requestRepositoryStream(test, SendChangedPaths, address, &gitalypb.FindChangedPathsRequest{
		Repository: &gitalypb.Repository{StorageName: "default", RelativePath: "test.git"},
	})
	defer response.Body.Close()
	require.Equal(test, http.StatusOK, response.StatusCode)
	decoder := json.NewDecoder(response.Body)
	for range testhelper.GitalyFindChangedPathsResponseMock {
		var row map[string]interface{}
		require.NoError(test, decoder.Decode(&row))
		require.Len(test, row, 7)
		require.Contains(test, row, "old_mode")
		require.NotContains(test, row, "commit_id")
	}
	var extra map[string]interface{}
	require.ErrorIs(test, decoder.Decode(&extra), io.EOF)
}

func TestChangedPathsHTTPReportsMissingRevisionAsNotFound(test *testing.T) {
	const gitalyMessage = `resolving commit: revision can not be found: "missing"`
	address := startGRPCServer(test, func(server *grpc.Server) {
		gitalypb.RegisterDiffServiceServer(server, &mockDiffServiceServer{
			findChangedPathsFunc: func(_ *gitalypb.FindChangedPathsRequest, _ gitalypb.DiffService_FindChangedPathsServer) error {
				return status.Error(codes.NotFound, gitalyMessage)
			},
		})
	})
	response := requestRepositoryStream(test, SendChangedPaths, address, &gitalypb.FindChangedPathsRequest{})
	defer response.Body.Close()
	require.Equal(test, http.StatusNotFound, response.StatusCode)
	body, err := io.ReadAll(response.Body)
	require.NoError(test, err)
	require.Equal(test, gitalyMessage+"\n", string(body))
}

func TestChangedPathsEmptyHTTP(test *testing.T) {
	for _, finalError := range []error{nil, status.Error(codes.Unavailable, "interrupted empty response")} {
		test.Run(status.Code(finalError).String(), func(test *testing.T) {
			address := startGRPCServer(test, func(server *grpc.Server) {
				gitalypb.RegisterDiffServiceServer(server, &mockDiffServiceServer{
					findChangedPathsFunc: func(_ *gitalypb.FindChangedPathsRequest, stream gitalypb.DiffService_FindChangedPathsServer) error {
						if err := stream.Send(&gitalypb.FindChangedPathsResponse{}); err != nil {
							return err
						}
						return finalError
					},
				})
			})
			response := requestRepositoryStream(test, SendChangedPaths, address, &gitalypb.FindChangedPathsRequest{})
			defer response.Body.Close()
			body, err := io.ReadAll(response.Body)
			require.NoError(test, err)
			if finalError == nil {
				require.Equal(test, http.StatusOK, response.StatusCode)
				require.Empty(test, body)
			} else {
				require.Equal(test, http.StatusInternalServerError, response.StatusCode)
			}
		})
	}
}

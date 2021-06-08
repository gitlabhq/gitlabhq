package gitaly

import (
	"context"
	"fmt"
	"io"

	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"
	"gitlab.com/gitlab-org/gitaly/v14/streamio"
)

// RepositoryClient encapsulates RepositoryService calls
type RepositoryClient struct {
	gitalypb.RepositoryServiceClient
}

// ArchiveReader performs a GetArchive Gitaly request and returns an io.Reader
// for the response
func (client *RepositoryClient) ArchiveReader(ctx context.Context, request *gitalypb.GetArchiveRequest) (io.Reader, error) {
	c, err := client.GetArchive(ctx, request)
	if err != nil {
		return nil, fmt.Errorf("RepositoryService::GetArchive: %v", err)
	}

	return streamio.NewReader(func() ([]byte, error) {
		resp, err := c.Recv()

		return resp.GetData(), err
	}), nil
}

// SnapshotReader performs a GetSnapshot Gitaly request and returns an io.Reader
// for the response
func (client *RepositoryClient) SnapshotReader(ctx context.Context, request *gitalypb.GetSnapshotRequest) (io.Reader, error) {
	c, err := client.GetSnapshot(ctx, request)
	if err != nil {
		return nil, fmt.Errorf("RepositoryService::GetSnapshot: %v", err)
	}

	return streamio.NewReader(func() ([]byte, error) {
		resp, err := c.Recv()

		return resp.GetData(), err
	}), nil
}

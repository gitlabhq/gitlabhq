package gitaly

import (
	"context"
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"
	"gitlab.com/gitlab-org/gitaly/v16/streamio"
)

// DiffClient wraps the Gitaly DiffServiceClient.
type DiffClient struct {
	gitalypb.DiffServiceClient
}

func (client *DiffClient) sendStream(w http.ResponseWriter, recv func() ([]byte, error)) error {
	w.Header().Del("Content-Length")

	rr := streamio.NewReader(recv)

	if _, err := io.Copy(w, rr); err != nil {
		return fmt.Errorf("copy rpc data: %v", err)
	}

	return nil
}

// SendRawDiff streams a raw diff to the HTTP response.
func (client *DiffClient) SendRawDiff(ctx context.Context, w http.ResponseWriter, request *gitalypb.RawDiffRequest) error {
	c, err := client.RawDiff(ctx, request)
	if err != nil {
		return fmt.Errorf("rpc failed: %v", err)
	}

	return client.sendStream(w, func() ([]byte, error) {
		resp, err := c.Recv()
		return resp.GetData(), err
	})
}

// SendRawPatch streams a raw patch to the HTTP response.
func (client *DiffClient) SendRawPatch(ctx context.Context, w http.ResponseWriter, request *gitalypb.RawPatchRequest) error {
	c, err := client.RawPatch(ctx, request)
	if err != nil {
		return fmt.Errorf("rpc failed: %v", err)
	}

	return client.sendStream(w, func() ([]byte, error) {
		resp, err := c.Recv()
		return resp.GetData(), err
	})
}

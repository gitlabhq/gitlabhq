package gitaly

import (
	"context"
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"
	"gitlab.com/gitlab-org/gitaly/v14/streamio"
)

type DiffClient struct {
	gitalypb.DiffServiceClient
}

func (client *DiffClient) SendRawDiff(ctx context.Context, w http.ResponseWriter, request *gitalypb.RawDiffRequest) error {
	c, err := client.RawDiff(ctx, request)
	if err != nil {
		return fmt.Errorf("rpc failed: %v", err)
	}

	w.Header().Del("Content-Length")

	rr := streamio.NewReader(func() ([]byte, error) {
		resp, err := c.Recv()
		return resp.GetData(), err
	})

	if _, err := io.Copy(w, rr); err != nil {
		return fmt.Errorf("copy rpc data: %v", err)
	}

	return nil
}

func (client *DiffClient) SendRawPatch(ctx context.Context, w http.ResponseWriter, request *gitalypb.RawPatchRequest) error {
	c, err := client.RawPatch(ctx, request)
	if err != nil {
		return fmt.Errorf("rpc failed: %v", err)
	}

	w.Header().Del("Content-Length")

	rr := streamio.NewReader(func() ([]byte, error) {
		resp, err := c.Recv()
		return resp.GetData(), err
	})

	if _, err := io.Copy(w, rr); err != nil {
		return fmt.Errorf("copy rpc data: %v", err)
	}

	return nil
}

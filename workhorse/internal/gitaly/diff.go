package gitaly

import (
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"
	"gitlab.com/gitlab-org/gitaly/v18/streamio"
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

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")

	return client.sendStream(w, func() ([]byte, error) {
		resp, err := c.Recv()
		return resp.GetData(), err
	})
}

// changedPathEntry represents a single changed path as NDJSON.
type changedPathEntry struct {
	Path      string `json:"path"`
	Status    string `json:"status"`
	OldPath   string `json:"old_path"`
	NewMode   int32  `json:"new_mode"`
	OldBlobID string `json:"old_blob_id"`
	NewBlobID string `json:"new_blob_id"`
}

// SendFindChangedPaths streams changed paths from Gitaly as newline-delimited JSON.
func (client *DiffClient) SendFindChangedPaths(ctx context.Context, w http.ResponseWriter, request *gitalypb.FindChangedPathsRequest) error {
	stream, err := client.FindChangedPaths(ctx, request)
	if err != nil {
		return fmt.Errorf("rpc failed: %v", err)
	}

	w.Header().Set("Content-Type", "application/x-ndjson")
	w.Header().Del("Content-Length")

	encoder := json.NewEncoder(w)

	for {
		resp, err := stream.Recv()
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("receive changed paths: %v", err)
		}

		for _, path := range resp.GetPaths() {
			entry := changedPathEntry{
				Path:      string(path.GetPath()),
				Status:    path.GetStatus().String(),
				OldPath:   string(path.GetOldPath()),
				NewMode:   path.GetNewMode(),
				OldBlobID: path.GetOldBlobId(),
				NewBlobID: path.GetNewBlobId(),
			}
			if err := encoder.Encode(entry); err != nil {
				return fmt.Errorf("encode changed path: %v", err)
			}
		}

		if flusher, ok := w.(http.Flusher); ok {
			flusher.Flush()
		}
	}

	return nil
}

// SendRawPatch streams a raw patch to the HTTP response.
func (client *DiffClient) SendRawPatch(ctx context.Context, w http.ResponseWriter, request *gitalypb.RawPatchRequest) error {
	c, err := client.RawPatch(ctx, request)
	if err != nil {
		return fmt.Errorf("rpc failed: %v", err)
	}

	w.Header().Set("Content-Type", "text/plain; charset=utf-8")

	return client.sendStream(w, func() ([]byte, error) {
		resp, err := c.Recv()
		return resp.GetData(), err
	})
}

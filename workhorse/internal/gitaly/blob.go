package gitaly

import (
	"context"
	"encoding/binary"
	"fmt"
	"io"
	"math"
	"net/http"
	"strconv"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"
	"gitlab.com/gitlab-org/gitaly/v18/streamio"
	"google.golang.org/protobuf/proto"
)

// BlobClient wraps the gRPC client for Gitaly's BlobService.
type BlobClient struct {
	gitalypb.BlobServiceClient
}

// SendBlob streams the blob data from Gitaly to the HTTP response writer.
func (client *BlobClient) SendBlob(ctx context.Context, w http.ResponseWriter, request *gitalypb.GetBlobRequest) error {
	c, err := client.GetBlob(ctx, request)
	if err != nil {
		return fmt.Errorf("rpc failed: %v", err)
	}

	firstResponseReceived := false
	rr := streamio.NewReader(func() ([]byte, error) {
		resp, err := c.Recv()

		if !firstResponseReceived && err == nil {
			firstResponseReceived = true
			w.Header().Set("Content-Length", strconv.FormatInt(resp.GetSize(), 10))
		}

		return resp.GetData(), err
	})

	if _, err := io.Copy(w, rr); err != nil {
		return fmt.Errorf("copy rpc data: %v", err)
	}

	return nil
}

// SendListBlobs streams blobs from Gitaly as length-prefixed protobuf frames.
// Each frame is a 4-byte big-endian length followed by the serialized ListBlobsResponse.
func (client *BlobClient) SendListBlobs(ctx context.Context, w http.ResponseWriter, request *gitalypb.ListBlobsRequest) error {
	stream, err := client.ListBlobs(ctx, request)
	if err != nil {
		return fmt.Errorf("rpc failed: %v", err)
	}

	w.Header().Set("Content-Type", "application/octet-stream")
	w.Header().Del("Content-Length")

	for {
		resp, err := stream.Recv()
		if err == io.EOF {
			break
		}
		if err != nil {
			return fmt.Errorf("receive list blobs: %v", err)
		}

		frame, err := proto.Marshal(resp)
		if err != nil {
			return fmt.Errorf("marshal list blobs response: %v", err)
		}

		if len(frame) > math.MaxUint32 {
			return fmt.Errorf("frame too large: %d bytes", len(frame))
		}

		var lengthPrefix [4]byte
		binary.BigEndian.PutUint32(lengthPrefix[:], uint32(len(frame))) // #nosec G115 -- overflow guarded above
		if _, err := w.Write(lengthPrefix[:]); err != nil {
			return fmt.Errorf("write frame length: %v", err)
		}
		if _, err := w.Write(frame); err != nil {
			return fmt.Errorf("write frame data: %v", err)
		}

		if flusher, ok := w.(http.Flusher); ok {
			flusher.Flush()
		}
	}

	return nil
}

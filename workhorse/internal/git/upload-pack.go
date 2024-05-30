package git

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"time"

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
)

var (
	uploadPackTimeout = 10 * time.Minute
)

// Will not return a non-nil error after the response body has been
// written to.
func handleUploadPack(w *HTTPResponseWriter, r *http.Request, a *api.Response) (*gitalypb.PackfileNegotiationStatistics, error) {
	ctx := r.Context()

	// Prevent the client from holding the connection open indefinitely. A
	// transfer rate of 17KiB/sec is sufficient to send 10MiB of data in
	// ten minutes, which seems adequate. Most requests will be much smaller.
	// This mitigates a use-after-check issue.
	//
	// We can't reliably interrupt the read from a http handler, but we can
	// ensure the request will (eventually) fail: https://github.com/golang/go/issues/16100
	readerCtx, cancel := context.WithTimeout(ctx, uploadPackTimeout)
	defer cancel()

	limited := newContextReader(readerCtx, r.Body)
	cr, cw := newWriteAfterReader(limited, w)
	defer cw.Flush()

	action := getService(r)
	writePostRPCHeader(w, action)

	gitProtocol := r.Header.Get("Git-Protocol")

	return handleUploadPackWithGitaly(ctx, a, cr, cw, gitProtocol)
}

func handleUploadPackWithGitaly(ctx context.Context, a *api.Response, clientRequest io.Reader, clientResponse io.Writer, gitProtocol string) (*gitalypb.PackfileNegotiationStatistics, error) {
	ctx, smarthttp, err := gitaly.NewSmartHTTPClient(ctx, a.GitalyServer)
	if err != nil {
		return nil, fmt.Errorf("get gitaly client: %w", err)
	}

	resp, err := smarthttp.UploadPack(ctx, &a.Repository, clientRequest, clientResponse, gitConfigOptions(a), gitProtocol)
	if err != nil {
		return nil, fmt.Errorf("do gitaly call: %w", err)
	}

	return resp.PackfileNegotiationStatistics, nil
}

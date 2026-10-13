package git

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"gitlab.com/gitlab-org/gitaly/v19/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

const (
	// gitProtocolV2 is the Git-Protocol header value requesting protocol version 2.
	gitProtocolV2 = "version=2"
	// commandPrefix marks the pktline naming the protocol v2 command being requested.
	commandPrefix = "command="
	// bundleURICommand is the protocol v2 command Git sends to negotiate bundle URIs.
	bundleURICommand = "bundle-uri"
	// pktLinePrefixLen is the number of hex digits prefixing every pktline. The length they
	// encode counts the prefix itself.
	pktLinePrefixLen = 4
	// commandPeekSize bounds how far into the request the command pktline is looked for. Git
	// sends it among the leading capabilities, which are an order of magnitude smaller.
	commandPeekSize = 256
	// uploadPackBufferSize matches io.Copy's internal buffer size. bufio.Reader implements
	// io.WriterTo, so io.Copy defers to it and the buffer size becomes the size of each
	// sidechannel write; a smaller buffer would mean more pktline frames per request body.
	uploadPackBufferSize = 32 * 1024
)

var (
	uploadPackTimeout = 10 * time.Minute
)

// Will not return a non-nil error after the response body has been
// written to.
func handleUploadPack(w *HTTPResponseWriter, r *http.Request, a *api.Response) (*gitalypb.PackfileNegotiationStatistics, error) {
	ctx := r.Context()

	// Extract correlation ID from X-Gitaly-Correlation-Id header and store in context
	if correlationID := r.Header.Get(XGitalyCorrelationID); correlationID != "" {
		ctx = context.WithValue(ctx, gitaly.GitalyCorrelationIDKey, correlationID)
	}

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
	defer func() {
		if err := cw.Flush(); err != nil {
			log.WithError(err).Error("Could not flush upload-pack response")
		}
	}()

	action := getService(r)
	writePostRPCHeader(w, action)

	gitProtocol := r.Header.Get("Git-Protocol")

	clientRequest, serve := cr, handleUploadPackWithGitaly
	if gitProtocol == gitProtocolV2 && a.BundleURIDedicatedRPC {
		// Buffer the body so the command can be peeked at without consuming it, leaving the
		// request intact for whichever RPC ends up serving it.
		buffered := bufio.NewReaderSize(cr, uploadPackBufferSize)
		clientRequest = buffered

		// A short read is safe: the command sits near the front, so a truncated window can
		// only fail to find it, never match the wrong one.
		peeked, _ := buffered.Peek(commandPeekSize)
		if isBundleURIRequest(peeked) {
			serve = handleAdvertiseBundleURIWithGitaly
		}
	}

	return serve(ctx, a, clientRequest, cw, gitProtocol)
}

// isBundleURIRequest reports whether the leading pktlines carry the protocol v2
// `command=bundle-uri` command. The command pktline is not necessarily first — Git sends it after
// the agent and object-format capabilities — so they are scanned for it. A malformed or truncated
// request is left to Git to reject.
func isBundleURIRequest(peeked []byte) bool {
	for len(peeked) >= pktLinePrefixLen {
		length, err := strconv.ParseUint(string(peeked[:pktLinePrefixLen]), 16, 16)
		if err != nil {
			return false
		}

		// Anything shorter than its own prefix is a flush or delimiter pktline, which ends
		// the command section. A length past the window means the command is out of reach.
		if length < pktLinePrefixLen || int(length) > len(peeked) {
			return false
		}

		payload := string(peeked[pktLinePrefixLen:length])
		if command, found := strings.CutPrefix(payload, commandPrefix); found {
			// Git terminates the command with a newline for some commands but not others.
			return strings.TrimSuffix(command, "\n") == bundleURICommand
		}

		peeked = peeked[length:]
	}

	return false
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

func handleAdvertiseBundleURIWithGitaly(ctx context.Context, a *api.Response, clientRequest io.Reader, clientResponse io.Writer, gitProtocol string) (*gitalypb.PackfileNegotiationStatistics, error) {
	ctx, smarthttp, err := gitaly.NewSmartHTTPClient(ctx, a.GitalyServer)
	if err != nil {
		return nil, fmt.Errorf("get gitaly client: %w", err)
	}

	resp, err := smarthttp.BundleURI(ctx, &a.Repository, clientRequest, clientResponse, gitConfigOptions(a), gitProtocol)
	if err != nil {
		return nil, fmt.Errorf("do gitaly call: %w", err)
	}

	return resp.GetPackfileNegotiationStatistics(), nil
}

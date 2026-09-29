package git

import (
	"bufio"
	"context"
	"fmt"
	"io"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"

	"gitlab.com/gitlab-org/gitaly/v19/client"
	"gitlab.com/gitlab-org/gitaly/v19/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

var (
	originalUploadPackTimeout = uploadPackTimeout
)

type waitReader struct {
	t time.Duration
}

func (f *waitReader) Read(_ []byte) (int, error) {
	time.Sleep(f.t)
	return 0, io.EOF
}

type smartHTTPServiceServer struct {
	gitalypb.UnimplementedSmartHTTPServiceServer
	handler func(context.Context, *gitalypb.PostUploadPackWithSidechannelRequest) (*gitalypb.PostUploadPackWithSidechannelResponse, error)
}

func (srv *smartHTTPServiceServer) PostUploadPackWithSidechannel(ctx context.Context, req *gitalypb.PostUploadPackWithSidechannelRequest) (*gitalypb.PostUploadPackWithSidechannelResponse, error) {
	return srv.handler(ctx, req)
}

func TestUploadPackTimesOut(t *testing.T) {
	uploadPackTimeout = time.Millisecond
	defer func() { uploadPackTimeout = originalUploadPackTimeout }()

	addr := startSmartHTTPServer(t, &smartHTTPServiceServer{
		handler: func(ctx context.Context, _ *gitalypb.PostUploadPackWithSidechannelRequest) (*gitalypb.PostUploadPackWithSidechannelResponse, error) {
			conn, err := client.OpenServerSidechannel(ctx)
			if err != nil {
				return nil, err
			}
			defer conn.Close()

			_, _ = io.Copy(io.Discard, conn)
			return &gitalypb.PostUploadPackWithSidechannelResponse{}, nil
		},
	})

	body := &waitReader{t: 10 * time.Millisecond}

	w := httptest.NewRecorder()
	r := httptest.NewRequest("GET", "/", body)
	a := &api.Response{GitalyServer: api.GitalyServer{Address: addr}}

	_, err := handleUploadPack(NewHTTPResponseWriter(w), r, a)
	require.ErrorIs(t, err, context.DeadlineExceeded)
}

// startSmartHTTPServer is a convenience wrapper around startGRPCServer
// that registers a SmartHTTPService.
func startSmartHTTPServer(t testing.TB, s gitalypb.SmartHTTPServiceServer) string {
	t.Helper()

	return startGRPCServer(t, func(srv *grpc.Server) {
		gitalypb.RegisterSmartHTTPServiceServer(srv, s)
	})
}

// recordingSmartHTTPServer serves both upload-pack RPCs and reports which one was invoked along
// with the request bytes it received over the sidechannel.
type recordingSmartHTTPServer struct {
	gitalypb.UnimplementedSmartHTTPServiceServer
	invokedRPC chan string
	request    chan string
}

func newRecordingSmartHTTPServer() *recordingSmartHTTPServer {
	return &recordingSmartHTTPServer{
		invokedRPC: make(chan string, 1),
		request:    make(chan string, 1),
	}
}

func (srv *recordingSmartHTTPServer) PostUploadPackWithSidechannel(ctx context.Context, _ *gitalypb.PostUploadPackWithSidechannelRequest) (*gitalypb.PostUploadPackWithSidechannelResponse, error) {
	if err := srv.record(ctx, "PostUploadPackWithSidechannel"); err != nil {
		return nil, err
	}

	return &gitalypb.PostUploadPackWithSidechannelResponse{}, nil
}

func (srv *recordingSmartHTTPServer) AdvertiseBundleURI(ctx context.Context, _ *gitalypb.AdvertiseBundleURIRequest) (*gitalypb.AdvertiseBundleURIResponse, error) {
	if err := srv.record(ctx, "AdvertiseBundleURI"); err != nil {
		return nil, err
	}

	return &gitalypb.AdvertiseBundleURIResponse{}, nil
}

func (srv *recordingSmartHTTPServer) record(ctx context.Context, rpc string) error {
	conn, err := client.OpenServerSidechannel(ctx)
	if err != nil {
		return err
	}
	defer conn.Close()

	request, err := io.ReadAll(conn)
	if err != nil {
		return err
	}

	srv.invokedRPC <- rpc
	srv.request <- string(request)

	return nil
}

func TestUploadPackBundleURIRouting(t *testing.T) {
	// Request bodies as captured from git 2.55.0. Note that Git puts the capability pktlines
	// before the command, and terminates command=bundle-uri with a newline but not
	// command=fetch.
	const (
		bundleURIBody = "001bagent=git/2.55.0-Darwin0016object-format=sha10017command=bundle-uri\n00010000"
		fetchBody     = "0011command=fetch001bagent=git/2.55.0-Darwin0016object-format=sha10001000dthin-pack0032want 6392e496d7ba8293adafa88221b1f6ed9b3d54ce\n00000009done\n"
	)

	for _, tc := range []struct {
		desc        string
		flagEnabled bool
		gitProtocol string
		body        string
		expectedRPC string
	}{
		{
			desc:        "bundle-uri command with the flag enabled",
			flagEnabled: true,
			gitProtocol: gitProtocolV2,
			body:        bundleURIBody,
			expectedRPC: "AdvertiseBundleURI",
		},
		{
			desc:        "bundle-uri command with the flag disabled",
			gitProtocol: gitProtocolV2,
			body:        bundleURIBody,
			expectedRPC: "PostUploadPackWithSidechannel",
		},
		{
			desc:        "bundle-uri command without protocol v2",
			flagEnabled: true,
			gitProtocol: "version=1",
			body:        bundleURIBody,
			expectedRPC: "PostUploadPackWithSidechannel",
		},
		{
			desc:        "fetch command with the flag enabled",
			flagEnabled: true,
			gitProtocol: gitProtocolV2,
			body:        fetchBody,
			expectedRPC: "PostUploadPackWithSidechannel",
		},
		{
			desc:        "bundle-uri command without a protocol header",
			flagEnabled: true,
			body:        bundleURIBody,
			expectedRPC: "PostUploadPackWithSidechannel",
		},
		{
			desc:        "fetch command with a body larger than the read buffer",
			flagEnabled: true,
			gitProtocol: gitProtocolV2,
			body:        largeFetchBody(),
			expectedRPC: "PostUploadPackWithSidechannel",
		},
	} {
		t.Run(tc.desc, func(t *testing.T) {
			srv := newRecordingSmartHTTPServer()
			addr := startSmartHTTPServer(t, srv)

			w := httptest.NewRecorder()
			r := httptest.NewRequest("POST", "/", strings.NewReader(tc.body))
			r.Header.Set("Git-Protocol", tc.gitProtocol)
			a := &api.Response{
				GitalyServer:          api.GitalyServer{Address: addr},
				BundleURIDedicatedRPC: tc.flagEnabled,
			}

			_, err := handleUploadPack(NewHTTPResponseWriter(w), r, a)
			require.NoError(t, err)

			require.Equal(t, tc.expectedRPC, <-srv.invokedRPC)
			// Peeking the command must leave the request body intact.
			require.Equal(t, tc.body, <-srv.request)
		})
	}
}

func TestIsBundleURIRequest(t *testing.T) {
	const (
		agent        = "001bagent=git/2.55.0-Darwin"
		objectFormat = "0016object-format=sha1"
	)

	for _, tc := range []struct {
		desc     string
		body     string
		expected bool
	}{
		{desc: "command after capabilities, as git sends it", body: agent + objectFormat + "0017command=bundle-uri\n00010000", expected: true},
		{desc: "command first", body: "0017command=bundle-uri\n0000", expected: true},
		{desc: "command without trailing newline", body: "0016command=bundle-uri0000", expected: true},
		{desc: "command with nothing after it", body: agent + "0017command=bundle-uri\n", expected: true},
		{desc: "fetch command", body: "0011command=fetch" + agent + objectFormat, expected: false},
		{desc: "ls-refs command", body: "0014command=ls-refs\n" + agent, expected: false},
		{desc: "protocol v0 want line", body: "0032want 74730d410fcb6603ace96f1dc55ea6196122532d\n", expected: false},
		{desc: "capabilities with no command at all", body: agent + objectFormat + "0000", expected: false},
		{desc: "command beyond the peek window", body: strings.Repeat("0005x", 60) + "0017command=bundle-uri\n", expected: false},
		{desc: "mismatched length prefix", body: "0018command=bundle-uri\n0000", expected: false},
		{desc: "non-hex length prefix", body: "zzzzcommand=bundle-uri\n0000", expected: false},
		{desc: "non-hex prefix on a later pktline", body: agent + "zzzzcommand=bundle-uri\n", expected: false},
		{desc: "truncated body", body: "0017command=bundle", expected: false},
		{desc: "flush pktline only", body: "0000", expected: false},
		{desc: "delimiter pktline only", body: "0001", expected: false},
		{desc: "empty body", body: "", expected: false},
	} {
		t.Run(tc.desc, func(t *testing.T) {
			body := bufio.NewReaderSize(strings.NewReader(tc.body), uploadPackBufferSize)
			peeked, _ := body.Peek(commandPeekSize)
			require.Equal(t, tc.expected, isBundleURIRequest(peeked))

			// Peeking must leave the body intact for the RPC that serves it.
			rest, err := io.ReadAll(body)
			require.NoError(t, err)
			require.Equal(t, tc.body, string(rest))
		})
	}
}

// largeFetchBody returns a fetch request bigger than the read buffer, so that the buffer-refill
// path is exercised while the body is streamed to Gitaly.
func largeFetchBody() string {
	body := &strings.Builder{}
	body.WriteString("0011command=fetch")
	for i := 0; i < uploadPackBufferSize/50+100; i++ {
		fmt.Fprintf(body, "0032want %040x\n", i)
	}
	body.WriteString("0009done\n")

	return body.String()
}

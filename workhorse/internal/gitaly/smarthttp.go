package gitaly

import (
	"context"
	"encoding/json"
	"fmt"
	"io"

	gitalyclient "gitlab.com/gitlab-org/gitaly/v19/client"
	"gitlab.com/gitlab-org/gitaly/v19/proto/go/gitalypb"
	"gitlab.com/gitlab-org/gitaly/v19/streamio"
	"google.golang.org/grpc/metadata"
)

// ClientContextMetadataKey is the key used by rails to propagate client context back to internal APIs
const ClientContextMetadataKey = "gitaly-client-context-bin"

// SmartHTTPClient encapsulates the SmartHTTPServiceClient for Gitaly.
type SmartHTTPClient struct {
	sidechannelRegistry *gitalyclient.SidechannelRegistry
	gitalypb.SmartHTTPServiceClient
}

// InfoRefsResponseReader handles InfoRefs requests and returns an io.Reader for the response.
func (client *SmartHTTPClient) InfoRefsResponseReader(ctx context.Context, repo *gitalypb.Repository, rpc string, gitConfigOptions []string, gitProtocol string) (io.Reader, error) {
	rpcRequest := &gitalypb.InfoRefsRequest{
		Repository:       repo,
		GitConfigOptions: gitConfigOptions,
		GitProtocol:      gitProtocol,
	}

	switch rpc {
	case "git-upload-pack":
		stream, err := client.InfoRefsUploadPack(ctx, rpcRequest)
		return infoRefsReader(stream), err
	case "git-receive-pack":
		stream, err := client.InfoRefsReceivePack(ctx, rpcRequest)
		return infoRefsReader(stream), err
	default:
		return nil, fmt.Errorf("InfoRefsResponseWriterTo: Unsupported RPC: %q", rpc)
	}
}

type infoRefsClient interface {
	Recv() (*gitalypb.InfoRefsResponse, error)
}

func infoRefsReader(stream infoRefsClient) io.Reader {
	return streamio.NewReader(func() ([]byte, error) {
		resp, err := stream.Recv()
		return resp.GetData(), err
	})
}

// ReceivePack performs a receive pack operation with Git configuration options.
func (client *SmartHTTPClient) ReceivePack(ctx context.Context, repo *gitalypb.Repository, glID string, glUsername string, glRepository string, gitConfigOptions []string, glScopedUserID string, glBuildID string, clientRequest io.Reader, clientResponse io.Writer, gitProtocol string) error {
	clientContextMetadata, err := json.Marshal(map[string]string{"glBuildId": glBuildID, "scoped-user-id": glScopedUserID})
	if err != nil {
		return err
	}
	ctx = metadata.AppendToOutgoingContext(ctx, ClientContextMetadataKey, string(clientContextMetadata))

	stream, err := client.PostReceivePack(ctx)
	if err != nil {
		return err
	}

	rpcRequest := &gitalypb.PostReceivePackRequest{
		Repository:       repo,
		GlId:             glID,
		GlUsername:       glUsername,
		GlRepository:     glRepository,
		GitConfigOptions: gitConfigOptions,
		GitProtocol:      gitProtocol,
	}

	if err := stream.Send(rpcRequest); err != nil {
		return fmt.Errorf("initial request: %v", err)
	}

	numStreams := 2
	errC := make(chan error, numStreams)

	go func() {
		rr := streamio.NewReader(func() ([]byte, error) {
			response, err := stream.Recv()
			return response.GetData(), err
		})
		_, err := io.Copy(clientResponse, rr)
		errC <- err
	}()

	go func() {
		sw := streamio.NewWriter(func(data []byte) error {
			return stream.Send(&gitalypb.PostReceivePackRequest{Data: data})
		})
		_, err := io.Copy(sw, clientRequest)
		_ = stream.CloseSend()
		errC <- err
	}()

	for i := 0; i < numStreams; i++ {
		if err := <-errC; err != nil {
			return err
		}
	}

	return nil
}

// copyOverSidechannel streams the client's request to git-upload-pack(1) and its response back
// over the sidechannel. Shared by every upload-pack RPC, which differ only in the method invoked.
func copyOverSidechannel(clientRequest io.Reader, clientResponse io.Writer) func(gitalyclient.SidechannelConn) error {
	return func(conn gitalyclient.SidechannelConn) error {
		if _, err := io.Copy(conn, clientRequest); err != nil {
			return fmt.Errorf("copy request body: %w", err)
		}

		if err := conn.CloseWrite(); err != nil {
			return fmt.Errorf("close request body: %w", err)
		}

		if _, err := io.Copy(clientResponse, conn); err != nil {
			return fmt.Errorf("copy response body: %w", err)
		}

		return nil
	}
}

// uploadPackOverSidechannel registers the sidechannel, invokes call over it, and waits for the
// copy to finish. The upload-pack RPCs differ only in the method they call, so they share this.
func uploadPackOverSidechannel[Resp any](
	ctx context.Context,
	client *SmartHTTPClient,
	clientRequest io.Reader,
	clientResponse io.Writer,
	rpcName string,
	call func(context.Context) (Resp, error),
) (Resp, error) {
	var zero Resp

	ctx, waiter := client.sidechannelRegistry.Register(ctx, copyOverSidechannel(clientRequest, clientResponse))
	defer waiter.Close() //nolint:errcheck

	resp, err := call(ctx)
	if err != nil {
		return zero, fmt.Errorf("%s: %w", rpcName, err)
	}

	if err = waiter.Close(); err != nil {
		return zero, fmt.Errorf("close sidechannel waiter: %w", err)
	}

	return resp, nil
}

// UploadPack performs an upload pack operation with a sidechannel.
func (client *SmartHTTPClient) UploadPack(ctx context.Context, repo *gitalypb.Repository, clientRequest io.Reader, clientResponse io.Writer, gitConfigOptions []string, gitProtocol string) (*gitalypb.PostUploadPackWithSidechannelResponse, error) {
	return uploadPackOverSidechannel(ctx, client, clientRequest, clientResponse, "PostUploadPackWithSidechannel",
		func(ctx context.Context) (*gitalypb.PostUploadPackWithSidechannelResponse, error) {
			return client.PostUploadPackWithSidechannel(ctx, &gitalypb.PostUploadPackWithSidechannelRequest{
				Repository:       repo,
				GitConfigOptions: gitConfigOptions,
				GitProtocol:      gitProtocol,
			})
		})
}

// BundleURI serves the Git protocol v2 `command=bundle-uri` request. It is identical to UploadPack
// apart from the RPC it invokes: the dedicated method name gives this cheap command its own
// concurrency-limiting cost class on Gitaly, so it cannot queue behind clones.
func (client *SmartHTTPClient) BundleURI(ctx context.Context, repo *gitalypb.Repository, clientRequest io.Reader, clientResponse io.Writer, gitConfigOptions []string, gitProtocol string) (*gitalypb.AdvertiseBundleURIResponse, error) {
	return uploadPackOverSidechannel(ctx, client, clientRequest, clientResponse, "AdvertiseBundleURI",
		func(ctx context.Context) (*gitalypb.AdvertiseBundleURIResponse, error) {
			return client.AdvertiseBundleURI(ctx, &gitalypb.AdvertiseBundleURIRequest{
				Repository:       repo,
				GitConfigOptions: gitConfigOptions,
				GitProtocol:      gitProtocol,
			})
		})
}

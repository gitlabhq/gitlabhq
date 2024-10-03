package gitaly

import (
	"context"
	"fmt"
	"io"

	gitalyclient "gitlab.com/gitlab-org/gitaly/v16/client"
	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"
	"gitlab.com/gitlab-org/gitaly/v16/streamio"
)

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
func (client *SmartHTTPClient) ReceivePack(ctx context.Context, repo *gitalypb.Repository, glID string, glUsername string, glRepository string, gitConfigOptions []string, clientRequest io.Reader, clientResponse io.Writer, gitProtocol string) error {
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

// UploadPack performs an upload pack operation with a sidechannel.
func (client *SmartHTTPClient) UploadPack(ctx context.Context, repo *gitalypb.Repository, clientRequest io.Reader, clientResponse io.Writer, gitConfigOptions []string, gitProtocol string) (*gitalypb.PostUploadPackWithSidechannelResponse, error) {
	ctx, waiter := client.sidechannelRegistry.Register(ctx, func(conn gitalyclient.SidechannelConn) error {
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
	})
	defer waiter.Close() //nolint:errcheck

	rpcRequest := &gitalypb.PostUploadPackWithSidechannelRequest{
		Repository:       repo,
		GitConfigOptions: gitConfigOptions,
		GitProtocol:      gitProtocol,
	}

	resp, err := client.PostUploadPackWithSidechannel(ctx, rpcRequest)
	if err != nil {
		return nil, fmt.Errorf("PostUploadPackWithSidechannel: %w", err)
	}

	if err = waiter.Close(); err != nil {
		return nil, fmt.Errorf("close sidechannel waiter: %w", err)
	}

	return resp, nil
}

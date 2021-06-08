package gitaly

import (
	"context"
	"fmt"
	"io"

	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"
	"gitlab.com/gitlab-org/gitaly/v14/streamio"
)

type SmartHTTPClient struct {
	gitalypb.SmartHTTPServiceClient
}

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

func (client *SmartHTTPClient) ReceivePack(ctx context.Context, repo *gitalypb.Repository, glId string, glUsername string, glRepository string, gitConfigOptions []string, clientRequest io.Reader, clientResponse io.Writer, gitProtocol string) error {
	stream, err := client.PostReceivePack(ctx)
	if err != nil {
		return err
	}

	rpcRequest := &gitalypb.PostReceivePackRequest{
		Repository:       repo,
		GlId:             glId,
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
		stream.CloseSend()
		errC <- err
	}()

	for i := 0; i < numStreams; i++ {
		if err := <-errC; err != nil {
			return err
		}
	}

	return nil
}

func (client *SmartHTTPClient) UploadPack(ctx context.Context, repo *gitalypb.Repository, clientRequest io.Reader, clientResponse io.Writer, gitConfigOptions []string, gitProtocol string) error {
	stream, err := client.PostUploadPack(ctx)
	if err != nil {
		return err
	}

	rpcRequest := &gitalypb.PostUploadPackRequest{
		Repository:       repo,
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
			return stream.Send(&gitalypb.PostUploadPackRequest{Data: data})
		})
		_, err := io.Copy(sw, clientRequest)
		stream.CloseSend()
		errC <- err
	}()

	for i := 0; i < numStreams; i++ {
		if err := <-errC; err != nil {
			return err
		}
	}

	return nil
}

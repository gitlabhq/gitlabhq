// Package testhelper provides helper functions and utilities for testing Gitaly-related functionality.
package testhelper

import (
	"bytes"
	"fmt"
	"io"
	"os"
	"path"
	"strings"
	"sync"

	"github.com/sirupsen/logrus"
	"golang.org/x/net/context"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"

	"gitlab.com/gitlab-org/gitaly/v16/client"
	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"
	"gitlab.com/gitlab-org/labkit/log"
)

// GitalyTestServer is a test server implementation used for testing Gitaly-related functionality.
type GitalyTestServer struct {
	finalMessageCode codes.Code
	sync.WaitGroup
	LastIncomingMetadata metadata.MD
	gitalypb.UnimplementedSmartHTTPServiceServer
	gitalypb.UnimplementedRepositoryServiceServer
	gitalypb.UnimplementedBlobServiceServer
	gitalypb.UnimplementedDiffServiceServer
}

var (
	// GitalyInfoRefsResponseMock represents mock data for Gitaly's InfoRefsResponse.
	GitalyInfoRefsResponseMock = strings.Repeat("Mock Gitaly InfoRefsResponse data", 100000)
	// GitalyGetBlobResponseMock represents mock data for Gitaly's GetBlobResponse.
	GitalyGetBlobResponseMock = strings.Repeat("Mock Gitaly GetBlobResponse data", 100000)
	// GitalyGetArchiveResponseMock represents mock data for Gitaly's GetArchiveResponse.
	GitalyGetArchiveResponseMock = strings.Repeat("Mock Gitaly GetArchiveResponse data", 100000)
	// GitalyGetDiffResponseMock represents mock data for Gitaly's GetDiffResponse.
	GitalyGetDiffResponseMock = strings.Repeat("Mock Gitaly GetDiffResponse data", 100000)
	// GitalyGetPatchResponseMock represents mock data for Gitaly's GetPatchResponse.
	GitalyGetPatchResponseMock = strings.Repeat("Mock Gitaly GetPatchResponse data", 100000)

	// GitalyGetSnapshotResponseMock represents mock data for Gitaly's GetSnapshotResponse.
	GitalyGetSnapshotResponseMock = strings.Repeat("Mock Gitaly GetSnapshotResponse data", 100000)

	// GitalyReceivePackResponseMock represents mock data for Gitaly's ReceivePackResponse.
	GitalyReceivePackResponseMock []byte
	// GitalyUploadPackResponseMock represents mock data for Gitaly's UploadPackResponse.
	GitalyUploadPackResponseMock []byte
)

func init() {
	var err error
	if GitalyReceivePackResponseMock, err = os.ReadFile(path.Join(RootDir(), "testdata/receive-pack-fixture.txt")); err != nil {
		log.WithError(err).Fatal("Unable to read pack response")
	}
	if GitalyUploadPackResponseMock, err = os.ReadFile(path.Join(RootDir(), "testdata/upload-pack-fixture.txt")); err != nil {
		log.WithError(err).Fatal("Unable to read pack response")
	}
}

// NewGitalyServer creates a new instance of a Gitaly server for testing purposes.
func NewGitalyServer(finalMessageCode codes.Code) *GitalyTestServer {
	return &GitalyTestServer{finalMessageCode: finalMessageCode}
}

// InfoRefsUploadPack is a method on GitalyTestServer that handles the InfoRefsUploadPack RPC call.
func (s *GitalyTestServer) InfoRefsUploadPack(in *gitalypb.InfoRefsRequest, stream gitalypb.SmartHTTPService_InfoRefsUploadPackServer) error {
	s.WaitGroup.Add(1)
	defer s.WaitGroup.Done()

	if err := validateRepository(in.GetRepository()); err != nil {
		return err
	}

	fmt.Printf("Result: %+v\n", in)

	jsonString, err := marshalJSON(in)
	if err != nil {
		return err
	}

	data := []byte(strings.Join([]string{
		jsonString,
		"git-upload-pack",
		GitalyInfoRefsResponseMock,
	}, "\000"))

	s.LastIncomingMetadata = nil
	if md, ok := metadata.FromIncomingContext(stream.Context()); ok {
		s.LastIncomingMetadata = md
	}

	return s.sendInfoRefs(stream, data)
}

// InfoRefsReceivePack is a method on GitalyTestServer that handles the InfoRefsReceivePack RPC call.
func (s *GitalyTestServer) InfoRefsReceivePack(in *gitalypb.InfoRefsRequest, stream gitalypb.SmartHTTPService_InfoRefsReceivePackServer) error {
	s.WaitGroup.Add(1)
	defer s.WaitGroup.Done()

	if err := validateRepository(in.GetRepository()); err != nil {
		return err
	}

	fmt.Printf("Result: %+v\n", in)

	jsonString, err := marshalJSON(in)
	if err != nil {
		return err
	}

	data := []byte(strings.Join([]string{
		jsonString,
		"git-receive-pack",
		GitalyInfoRefsResponseMock,
	}, "\000"))

	return s.sendInfoRefs(stream, data)
}

func marshalJSON(msg proto.Message) (string, error) {
	b, err := protojson.Marshal(msg)
	if err != nil {
		return "", err
	}
	return string(b), nil
}

type infoRefsSender interface {
	Send(*gitalypb.InfoRefsResponse) error
}

func (s *GitalyTestServer) sendInfoRefs(stream infoRefsSender, data []byte) error {
	nSends, err := sendBytes(data, func(p []byte) error {
		return stream.Send(&gitalypb.InfoRefsResponse{Data: p})
	})
	if err != nil {
		return err
	}
	if nSends <= 1 {
		panic("should have sent more than one message")
	}

	return s.finalError()
}

// PostReceivePack is a method on GitalyTestServer that handles the PostReceivePack RPC call.
func (s *GitalyTestServer) PostReceivePack(stream gitalypb.SmartHTTPService_PostReceivePackServer) error {
	s.WaitGroup.Add(1)
	defer s.WaitGroup.Done()

	req, err := stream.Recv()
	if err != nil {
		return err
	}

	repo := req.GetRepository()
	if err = validateRepository(repo); err != nil {
		return err
	}

	jsonString, err := marshalJSON(req)
	if err != nil {
		return err
	}

	data := []byte(jsonString + "\000")

	// The body of the request starts in the second message
	for {
		req, err := stream.Recv()
		if err != nil {
			if err != io.EOF {
				return err
			}
			break
		}

		// We want to echo the request data back
		data = append(data, req.GetData()...)
	}

	nSends, _ := sendBytes(data, func(p []byte) error {
		return stream.Send(&gitalypb.PostReceivePackResponse{Data: p})
	})

	if nSends <= 1 {
		panic("should have sent more than one message")
	}

	return s.finalError()
}

// PostUploadPackWithSidechannel is a method on GitalyTestServer that handles the PostUploadPackWithSidechannel RPC call.
func (s *GitalyTestServer) PostUploadPackWithSidechannel(ctx context.Context, req *gitalypb.PostUploadPackWithSidechannelRequest) (*gitalypb.PostUploadPackWithSidechannelResponse, error) {
	s.WaitGroup.Add(1)
	defer s.WaitGroup.Done()

	if err := validateRepository(req.GetRepository()); err != nil {
		return nil, err
	}

	conn, err := client.OpenServerSidechannel(ctx)
	if err != nil {
		return nil, err
	}
	defer func() {
		if err = conn.Close(); err != nil {
			fmt.Printf("error closing sidechannel: %v\n", err)
		}
	}()

	jsonBytes, err := protojson.Marshal(req)
	if err != nil {
		return nil, err
	}

	if _, err := io.Copy(conn, io.MultiReader(
		bytes.NewReader(append(jsonBytes, 0)),
		conn,
	)); err != nil {
		return nil, err
	}

	return &gitalypb.PostUploadPackWithSidechannelResponse{}, s.finalError()
}

// CommitIsAncestor checks if one commit is an ancestor of another in the git repository.
func (s *GitalyTestServer) CommitIsAncestor(_ context.Context, _ *gitalypb.CommitIsAncestorRequest) (*gitalypb.CommitIsAncestorResponse, error) {
	return nil, nil
}

// GetBlob is a method on GitalyTestServer that handles the GetBlob RPC call.
func (s *GitalyTestServer) GetBlob(in *gitalypb.GetBlobRequest, stream gitalypb.BlobService_GetBlobServer) error {
	s.WaitGroup.Add(1)
	defer s.WaitGroup.Done()

	if err := validateRepository(in.GetRepository()); err != nil {
		return err
	}

	response := &gitalypb.GetBlobResponse{
		Oid:  in.GetOid(),
		Size: int64(len(GitalyGetBlobResponseMock)),
	}
	nSends, err := sendBytes([]byte(GitalyGetBlobResponseMock), func(p []byte) error {
		response.Data = p

		if err := stream.Send(response); err != nil {
			return err
		}

		// Use a new response so we don't send other fields (Size, ...) over and over
		response = &gitalypb.GetBlobResponse{}

		return nil
	})
	if err != nil {
		return err
	}
	if nSends <= 1 {
		panic("should have sent more than one message")
	}

	return s.finalError()
}

func (s *GitalyTestServer) GetArchive(in *gitalypb.GetArchiveRequest, stream gitalypb.RepositoryService_GetArchiveServer) error {
	s.WaitGroup.Add(1)
	defer s.WaitGroup.Done()

	if err := validateRepository(in.GetRepository()); err != nil {
		return err
	}

	nSends, err := sendBytes([]byte(GitalyGetArchiveResponseMock), func(p []byte) error {
		return stream.Send(&gitalypb.GetArchiveResponse{Data: p})
	})
	if err != nil {
		return err
	}
	if nSends <= 1 {
		panic("should have sent more than one message")
	}

	return s.finalError()
}

// RawDiff is a method on GitalyTestServer that handles the RawDiff RPC call.
func (s *GitalyTestServer) RawDiff(_ *gitalypb.RawDiffRequest, stream gitalypb.DiffService_RawDiffServer) error {
	nSends, err := sendBytes([]byte(GitalyGetDiffResponseMock), func(p []byte) error {
		return stream.Send(&gitalypb.RawDiffResponse{
			Data: p,
		})
	})
	if err != nil {
		return err
	}
	if nSends <= 1 {
		panic("should have sent more than one message")
	}

	return s.finalError()
}

func (s *GitalyTestServer) RawPatch(in *gitalypb.RawPatchRequest, stream gitalypb.DiffService_RawPatchServer) error {
	s.WaitGroup.Add(1)
	defer s.WaitGroup.Done()

	if err := validateRepository(in.GetRepository()); err != nil {
		return err
	}

	nSends, err := sendBytes([]byte(GitalyGetPatchResponseMock), func(p []byte) error {
		return stream.Send(&gitalypb.RawPatchResponse{
			Data: p,
		})
	})
	if err != nil {
		return err
	}
	if nSends <= 1 {
		panic("should have sent more than one message")
	}

	return s.finalError()
}

func (s *GitalyTestServer) GetSnapshot(in *gitalypb.GetSnapshotRequest, stream gitalypb.RepositoryService_GetSnapshotServer) error {
	s.WaitGroup.Add(1)
	defer s.WaitGroup.Done()

	if err := validateRepository(in.GetRepository()); err != nil {
		return err
	}

	nSends, err := sendBytes([]byte(GitalyGetSnapshotResponseMock), func(p []byte) error {
		return stream.Send(&gitalypb.GetSnapshotResponse{Data: p})
	})
	if err != nil {
		return err
	}
	if nSends <= 1 {
		panic("should have sent more than one message")
	}

	return s.finalError()
}

// sendBytes returns the number of times the 'sender' function was called and an error.
func sendBytes(data []byte, sender func([]byte) error) (int, error) {
	i := 0
	for ; len(data) > 0; i++ {
		n := 100
		if n > len(data) {
			n = len(data)
		}

		if err := sender(data[:n]); err != nil {
			return i, err
		}
		data = data[n:]
	}

	return i, nil
}

func (s *GitalyTestServer) finalError() error {
	if code := s.finalMessageCode; code != codes.OK {
		return status.Errorf(code, "error as specified by test")
	}

	return nil
}

func validateRepository(repo *gitalypb.Repository) error {
	if len(repo.GetStorageName()) == 0 {
		return fmt.Errorf("missing storage_name: %v", repo)
	}
	if len(repo.GetRelativePath()) == 0 {
		return fmt.Errorf("missing relative_path: %v", repo)
	}
	return nil
}

// WithSidechannel returns a gRPC server option to enable the sidechannel functionality.
func WithSidechannel() grpc.ServerOption {
	return client.SidechannelServer(logrus.NewEntry(logrus.StandardLogger()), insecure.NewCredentials())
}

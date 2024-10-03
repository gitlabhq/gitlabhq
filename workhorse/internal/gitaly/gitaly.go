/*
Package gitaly provides a comprehensive client for interacting with Gitaly services, facilitating operations on Git repositories. Key features include:

1. Streaming blob data from Gitaly Blob service, suitable for serving content over HTTP.
2. Retrieving and streaming diffs and patches from Gitaly server.
3. Managing gRPC connections to Gitaly server with connection caching and metadata handling.
4. Providing clients for various services including Blob, Repository, and Diff.
5. Retrieving repository archives and snapshots through the RepositoryService.
6. Handling Git operations via smart HTTP requests, including InfoRefs, ReceivePack, and UploadPack.
7. Supporting efficient streaming of request and response data.

This package enhances interaction with Git repositories managed by Gitaly, offering a streamlined interface for version control operations and data retrieval.
*/
package gitaly

import (
	"context"
	"fmt"
	"strings"
	"sync"

	grpc_prometheus "github.com/grpc-ecosystem/go-grpc-prometheus"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"
	"google.golang.org/protobuf/encoding/protojson"
	"google.golang.org/protobuf/proto"

	gitalyauth "gitlab.com/gitlab-org/gitaly/v16/auth"
	gitalyclient "gitlab.com/gitlab-org/gitaly/v16/client"
	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"

	grpccorrelation "gitlab.com/gitlab-org/labkit/correlation/grpc"
	grpctracing "gitlab.com/gitlab-org/labkit/tracing/grpc"
)

type cacheKey struct {
	address, token string
}

func getCacheKey(server api.GitalyServer) cacheKey {
	return cacheKey{address: server.Address, token: server.Token}
}

type connectionsCache struct {
	sync.RWMutex
	connections map[cacheKey]*grpc.ClientConn
}

var (
	// This connection cache map contains two types of connections:
	// - Normal gRPC connections
	// - Sidechannel connections. When client dials to the Gitaly server, the
	// server multiplexes the connection using Yamux. In the future, the server
	// can open another stream to transfer data without gRPC. Besides, we apply
	// a framing protocol to add the half-close capability to Yamux streams.
	// Hence, we cannot use those connections interchangeably.
	cache = connectionsCache{
		connections: make(map[cacheKey]*grpc.ClientConn),
	}
	sidechannelRegistry *gitalyclient.SidechannelRegistry

	connectionsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_gitaly_connections_total",
			Help: "Number of Gitaly connections that have been established",
		},
		[]string{"status"},
	)
)

// InitializeSidechannelRegistry creates the side channel registry if it doesn't exist.
func InitializeSidechannelRegistry(logger *logrus.Logger) {
	if sidechannelRegistry == nil {
		sidechannelRegistry = gitalyclient.NewSidechannelRegistry(logrus.NewEntry(logger))
	}
}

var allowedMetadataKeys = map[string]bool{
	"user_id":   true,
	"username":  true,
	"remote_ip": true,
}

func withOutgoingMetadata(ctx context.Context, gs api.GitalyServer) context.Context {
	md := metadata.New(nil)
	for k, v := range gs.CallMetadata {
		if strings.HasPrefix(k, "gitaly-feature-") || allowedMetadataKeys[k] {
			md.Set(k, v)
		}
	}
	return metadata.NewOutgoingContext(ctx, md)
}

// NewSmartHTTPClient is created and returns it with updated context.
func NewSmartHTTPClient(ctx context.Context, server api.GitalyServer) (context.Context, *SmartHTTPClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewSmartHTTPServiceClient(conn)
	smartHTTPClient := &SmartHTTPClient{
		SmartHTTPServiceClient: grpcClient,
		sidechannelRegistry:    sidechannelRegistry,
	}
	return withOutgoingMetadata(ctx, server), smartHTTPClient, nil
}

// NewBlobClient is created and returns it with updated context.
func NewBlobClient(ctx context.Context, server api.GitalyServer) (context.Context, *BlobClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewBlobServiceClient(conn)
	return withOutgoingMetadata(ctx, server), &BlobClient{grpcClient}, nil
}

// NewRepositoryClient is created and returns it with updated context.
func NewRepositoryClient(ctx context.Context, server api.GitalyServer) (context.Context, *RepositoryClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewRepositoryServiceClient(conn)
	return withOutgoingMetadata(ctx, server), &RepositoryClient{grpcClient}, nil
}

// NewDiffClient is created and returns it with updated context.
func NewDiffClient(ctx context.Context, server api.GitalyServer) (context.Context, *DiffClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewDiffServiceClient(conn)
	return withOutgoingMetadata(ctx, server), &DiffClient{grpcClient}, nil
}

// NewConnection returns a Gitaly connection
func NewConnection(server api.GitalyServer) (*grpc.ClientConn, error) {
	conn, err := getOrCreateConnection(server)

	return conn, err
}

// Sidechannel returns a Gitaly sidechannel
func Sidechannel() (*gitalyclient.SidechannelRegistry, error) {
	if sidechannelRegistry == nil {
		return nil, fmt.Errorf("sidechannel is not initialized")
	}

	return sidechannelRegistry, nil
}

func getOrCreateConnection(server api.GitalyServer) (*grpc.ClientConn, error) {
	key := getCacheKey(server)

	cache.RLock()
	conn := cache.connections[key]
	cache.RUnlock()

	if conn != nil {
		return conn, nil
	}

	cache.Lock()
	defer cache.Unlock()

	if cachedConn := cache.connections[key]; cachedConn != nil {
		return cachedConn, nil
	}

	newConn, err := newConnection(server)
	if err != nil {
		return nil, err
	}

	cache.connections[key] = newConn

	return newConn, nil
}

// CloseConnections closes all connections in cache.
func CloseConnections() {
	cache.Lock()
	defer cache.Unlock()

	for _, conn := range cache.connections {
		_ = conn.Close()
	}
}

func newConnection(server api.GitalyServer) (*grpc.ClientConn, error) {
	connOpts := gitalyclient.DefaultDialOpts
	connOpts = append(connOpts,
		grpc.WithPerRPCCredentials(gitalyauth.RPCCredentialsV2(server.Token)),
		grpc.WithChainStreamInterceptor(
			grpctracing.StreamClientTracingInterceptor(),
			grpc_prometheus.StreamClientInterceptor,
			grpccorrelation.StreamClientCorrelationInterceptor(
				grpccorrelation.WithClientName("gitlab-workhorse"),
			),
		),

		grpc.WithChainUnaryInterceptor(
			grpctracing.UnaryClientTracingInterceptor(),
			grpc_prometheus.UnaryClientInterceptor,
			grpccorrelation.UnaryClientCorrelationInterceptor(
				grpccorrelation.WithClientName("gitlab-workhorse"),
			),
		),
		// In https://gitlab.com/groups/gitlab-org/-/epics/8971, we added DNS discovery support to Praefect. This was
		// done by making two changes:
		// - Configure client-side round-robin load-balancing in client dial options. We added that as a default option
		// inside gitaly client in gitaly client since v15.9.0
		// - Configure DNS resolving. Due to some technical limitations, we don't use gRPC's built-in DNS resolver.
		// Instead, we implement our own DNS resolver. This resolver is exposed via the following configuration.
		// Afterward, workhorse can detect and handle DNS discovery automatically. The user needs to setup and set
		// Gitaly address to something like "dns:gitaly.service.dc1.consul"
		gitalyclient.WithGitalyDNSResolver(gitalyclient.DefaultDNSResolverBuilderConfig()),
	)

	conn, connErr := gitalyclient.DialSidechannel(context.Background(), server.Address, sidechannelRegistry, connOpts) // lint:allow context.Background

	label := "ok"
	if connErr != nil {
		label = "fail"
	}
	connectionsTotal.WithLabelValues(label).Inc()

	return conn, connErr
}

// UnmarshalJSON into a protobuf message.
func UnmarshalJSON(s string, msg proto.Message) error {
	return protojson.UnmarshalOptions{DiscardUnknown: true}.Unmarshal([]byte(s), msg)
}

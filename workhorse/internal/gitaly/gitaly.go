package gitaly

import (
	"context"
	"strings"
	"sync"

	"github.com/golang/protobuf/jsonpb" //lint:ignore SA1019 https://gitlab.com/gitlab-org/gitlab/-/issues/324868
	"github.com/golang/protobuf/proto"  //lint:ignore SA1019 https://gitlab.com/gitlab-org/gitlab/-/issues/324868
	grpc_middleware "github.com/grpc-ecosystem/go-grpc-middleware"
	grpc_prometheus "github.com/grpc-ecosystem/go-grpc-prometheus"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/sirupsen/logrus"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"

	gitalyauth "gitlab.com/gitlab-org/gitaly/v15/auth"
	gitalyclient "gitlab.com/gitlab-org/gitaly/v15/client"
	"gitlab.com/gitlab-org/gitaly/v15/proto/go/gitalypb"

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
	jsonUnMarshaler = jsonpb.Unmarshaler{AllowUnknownFields: true}
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

func InitializeSidechannelRegistry(logger *logrus.Logger) {
	if sidechannelRegistry == nil {
		sidechannelRegistry = gitalyclient.NewSidechannelRegistry(logrus.NewEntry(logger))
	}
}

type MetadataFunc func(metadata.MD)

func WithFeatures(features map[string]string) MetadataFunc {
	return func(md metadata.MD) {
		for k, v := range features {
			if !strings.HasPrefix(k, "gitaly-feature-") {
				continue
			}
			md.Append(k, v)
		}
	}
}

func WithLoggingMetadata(r *api.Response) MetadataFunc {
	return func(md metadata.MD) {
		if r.GL_ID != "" {
			md.Append("user_id", r.GL_ID)
		}
		if r.GL_USERNAME != "" {
			md.Append("username", r.GL_USERNAME)
		}
		if r.RemoteIp != "" {
			md.Append("remote_ip", r.RemoteIp)
		}
	}
}

func withOutgoingMetadata(ctx context.Context, addMetadataFuncs ...MetadataFunc) context.Context {
	md := metadata.New(nil)

	for _, f := range addMetadataFuncs {
		f(md)
	}

	return metadata.NewOutgoingContext(ctx, md)
}

func NewSmartHTTPClient(ctx context.Context, server api.GitalyServer, metadataFuncs ...MetadataFunc) (context.Context, *SmartHTTPClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewSmartHTTPServiceClient(conn)
	smartHTTPClient := &SmartHTTPClient{
		SmartHTTPServiceClient: grpcClient,
		sidechannelRegistry:    sidechannelRegistry,
	}

	return withOutgoingMetadata(
		ctx,
		metadataFuncs...,
	), smartHTTPClient, nil
}

func NewBlobClient(ctx context.Context, server api.GitalyServer, addMetadataFuncs ...MetadataFunc) (context.Context, *BlobClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewBlobServiceClient(conn)
	return withOutgoingMetadata(ctx, addMetadataFuncs...), &BlobClient{grpcClient}, nil
}

func NewRepositoryClient(ctx context.Context, server api.GitalyServer, addMetadataFuncs ...MetadataFunc) (context.Context, *RepositoryClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewRepositoryServiceClient(conn)
	return withOutgoingMetadata(ctx, addMetadataFuncs...), &RepositoryClient{grpcClient}, nil
}

// NewNamespaceClient is only used by the Gitaly integration tests at present
func NewNamespaceClient(ctx context.Context, server api.GitalyServer, addMetadataFuncs ...MetadataFunc) (context.Context, *NamespaceClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewNamespaceServiceClient(conn)
	return withOutgoingMetadata(ctx, addMetadataFuncs...), &NamespaceClient{grpcClient}, nil
}

func NewDiffClient(ctx context.Context, server api.GitalyServer, addMetadataFuncs ...MetadataFunc) (context.Context, *DiffClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewDiffServiceClient(conn)
	return withOutgoingMetadata(ctx, addMetadataFuncs...), &DiffClient{grpcClient}, nil
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

	if conn := cache.connections[key]; conn != nil {
		return conn, nil
	}

	conn, err := newConnection(server)
	if err != nil {
		return nil, err
	}

	cache.connections[key] = conn

	return conn, nil
}

func CloseConnections() {
	cache.Lock()
	defer cache.Unlock()

	for _, conn := range cache.connections {
		conn.Close()
	}
}

func newConnection(server api.GitalyServer) (*grpc.ClientConn, error) {
	connOpts := append(gitalyclient.DefaultDialOpts,
		grpc.WithPerRPCCredentials(gitalyauth.RPCCredentialsV2(server.Token)),
		grpc.WithStreamInterceptor(
			grpc_middleware.ChainStreamClient(
				grpctracing.StreamClientTracingInterceptor(),
				grpc_prometheus.StreamClientInterceptor,
				grpccorrelation.StreamClientCorrelationInterceptor(
					grpccorrelation.WithClientName("gitlab-workhorse"),
				),
			),
		),

		grpc.WithUnaryInterceptor(
			grpc_middleware.ChainUnaryClient(
				grpctracing.UnaryClientTracingInterceptor(),
				grpc_prometheus.UnaryClientInterceptor,
				grpccorrelation.UnaryClientCorrelationInterceptor(
					grpccorrelation.WithClientName("gitlab-workhorse"),
				),
			),
		),
	)

	conn, connErr := gitalyclient.DialSidechannel(context.Background(), server.Address, sidechannelRegistry, connOpts) // lint:allow context.Background

	label := "ok"
	if connErr != nil {
		label = "fail"
	}
	connectionsTotal.WithLabelValues(label).Inc()

	return conn, connErr
}

func UnmarshalJSON(s string, msg proto.Message) error {
	return jsonUnMarshaler.Unmarshal(strings.NewReader(s), msg)
}

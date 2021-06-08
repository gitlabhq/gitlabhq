package gitaly

import (
	"context"
	"strings"
	"sync"

	"github.com/golang/protobuf/jsonpb" //lint:ignore SA1019 https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/274
	"github.com/golang/protobuf/proto"  //lint:ignore SA1019 https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/274
	grpc_middleware "github.com/grpc-ecosystem/go-grpc-middleware"
	grpc_prometheus "github.com/grpc-ecosystem/go-grpc-prometheus"
	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	gitalyauth "gitlab.com/gitlab-org/gitaly/v14/auth"
	gitalyclient "gitlab.com/gitlab-org/gitaly/v14/client"
	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"

	grpccorrelation "gitlab.com/gitlab-org/labkit/correlation/grpc"
	grpctracing "gitlab.com/gitlab-org/labkit/tracing/grpc"
)

type Server struct {
	Address  string            `json:"address"`
	Token    string            `json:"token"`
	Features map[string]string `json:"features"`
}

type cacheKey struct{ address, token string }

func (server Server) cacheKey() cacheKey {
	return cacheKey{address: server.Address, token: server.Token}
}

type connectionsCache struct {
	sync.RWMutex
	connections map[cacheKey]*grpc.ClientConn
}

var (
	jsonUnMarshaler = jsonpb.Unmarshaler{AllowUnknownFields: true}
	cache           = connectionsCache{
		connections: make(map[cacheKey]*grpc.ClientConn),
	}

	connectionsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "gitlab_workhorse_gitaly_connections_total",
			Help: "Number of Gitaly connections that have been established",
		},
		[]string{"status"},
	)
)

func withOutgoingMetadata(ctx context.Context, features map[string]string) context.Context {
	md := metadata.New(nil)
	for k, v := range features {
		if !strings.HasPrefix(k, "gitaly-feature-") {
			continue
		}
		md.Append(k, v)
	}

	return metadata.NewOutgoingContext(ctx, md)
}

func NewSmartHTTPClient(ctx context.Context, server Server) (context.Context, *SmartHTTPClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewSmartHTTPServiceClient(conn)
	return withOutgoingMetadata(ctx, server.Features), &SmartHTTPClient{grpcClient}, nil
}

func NewBlobClient(ctx context.Context, server Server) (context.Context, *BlobClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewBlobServiceClient(conn)
	return withOutgoingMetadata(ctx, server.Features), &BlobClient{grpcClient}, nil
}

func NewRepositoryClient(ctx context.Context, server Server) (context.Context, *RepositoryClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewRepositoryServiceClient(conn)
	return withOutgoingMetadata(ctx, server.Features), &RepositoryClient{grpcClient}, nil
}

// NewNamespaceClient is only used by the Gitaly integration tests at present
func NewNamespaceClient(ctx context.Context, server Server) (context.Context, *NamespaceClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewNamespaceServiceClient(conn)
	return withOutgoingMetadata(ctx, server.Features), &NamespaceClient{grpcClient}, nil
}

func NewDiffClient(ctx context.Context, server Server) (context.Context, *DiffClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, nil, err
	}
	grpcClient := gitalypb.NewDiffServiceClient(conn)
	return withOutgoingMetadata(ctx, server.Features), &DiffClient{grpcClient}, nil
}

func getOrCreateConnection(server Server) (*grpc.ClientConn, error) {
	key := server.cacheKey()

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

func newConnection(server Server) (*grpc.ClientConn, error) {
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

	conn, connErr := gitalyclient.Dial(server.Address, connOpts)

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

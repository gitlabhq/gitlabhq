// Package orbit provides a workhorse integration with the GitLab Knowledge Graph (GKG) service via gRPC.
package orbit

import (
	"crypto/tls"
	"crypto/x509"
	"fmt"
	"strings"
	"sync"
	"time"

	grpc_prometheus "github.com/grpc-ecosystem/go-grpc-prometheus"
	"google.golang.org/grpc"
	"google.golang.org/grpc/connectivity"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/keepalive"

	gkgpb "gitlab.com/gitlab-org/orbit/knowledge-graph/clients/gkgpb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"

	grpccorrelation "gitlab.com/gitlab-org/labkit/correlation/grpc"
	grpctracing "gitlab.com/gitlab-org/labkit/tracing/grpc"
)

// GkgServer holds the connection parameters for a GKG gRPC server.
type GkgServer struct {
	Address string `json:"address"`
	JWT     string `json:"jwt"`
	TLS     bool   `json:"tls"`
}

type cacheKey struct {
	address string
}

type connectionsCache struct {
	sync.RWMutex
	connections map[cacheKey]*grpc.ClientConn
}

var cache = connectionsCache{
	connections: make(map[cacheKey]*grpc.ClientConn),
}

func getClient(server GkgServer) (gkgpb.KnowledgeGraphServiceClient, error) {
	conn, err := getOrCreateConnection(server)
	if err != nil {
		return nil, err
	}
	return gkgpb.NewKnowledgeGraphServiceClient(conn), nil
}

// getOrCreateConnection returns a cached gRPC connection or creates a new one.
// Connections in Shutdown or TransientFailure state are replaced.
// Connection rebalancing across GKG pods is handled server-side via
// MAX_CONNECTION_AGE in tonic (see https://gitlab.com/gitlab-org/orbit/knowledge-graph/-/work_items/330).
func getOrCreateConnection(server GkgServer) (*grpc.ClientConn, error) {
	key := cacheKey{address: server.Address}

	cache.RLock()
	conn := cache.connections[key]
	cache.RUnlock()

	if conn != nil && isConnUsable(conn) {
		return conn, nil
	}

	cache.Lock()
	defer cache.Unlock()

	if existing := cache.connections[key]; existing != nil {
		if isConnUsable(existing) {
			return existing, nil
		}
		_ = existing.Close()
		delete(cache.connections, key)
	}

	conn, err := newConnection(server)
	if err != nil {
		return nil, err
	}

	cache.connections[key] = conn
	return conn, nil
}

func isConnUsable(conn *grpc.ClientConn) bool {
	state := conn.GetState()
	return state != connectivity.Shutdown && state != connectivity.TransientFailure
}

func newConnection(server GkgServer) (*grpc.ClientConn, error) {
	opts := []grpc.DialOption{
		grpc.WithKeepaliveParams(keepalive.ClientParameters{
			Time:                60 * time.Second,
			Timeout:             20 * time.Second,
			PermitWithoutStream: true,
		}),
		grpc.WithDefaultCallOptions(
			grpc.MaxCallRecvMsgSize(8*1024*1024),
			grpc.MaxCallSendMsgSize(8*1024*1024),
		),
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
	}

	if server.TLS {
		certPool, err := x509.SystemCertPool()
		if err != nil {
			log.WithError(fmt.Errorf("orbit.client: failed to load system cert pool: %w", err)).Error()
			certPool = x509.NewCertPool()
		}
		opts = append(opts, grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{
			RootCAs:    certPool,
			MinVersion: tls.VersionTLS12,
		})))
	} else {
		opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))
	}

	return grpc.NewClient(stripScheme(server.Address), opts...)
}

// stripScheme removes tls:// and dns+tls: prefixes from the gRPC target,
// matching the Ruby client's strip_scheme behavior.
func stripScheme(target string) string {
	target = strings.TrimPrefix(target, "tcp://")
	target = strings.TrimPrefix(target, "tls://")
	if after, ok := strings.CutPrefix(target, "dns+tls:"); ok {
		target = "dns:" + after
	}
	return target
}

// CloseConnections closes all cached gRPC connections.
func CloseConnections() {
	cache.Lock()
	defer cache.Unlock()

	for key, conn := range cache.connections {
		_ = conn.Close()
		delete(cache.connections, key)
	}
}

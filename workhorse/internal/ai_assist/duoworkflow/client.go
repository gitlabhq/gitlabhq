// Package duoworkflow provides a client for interacting with the Duo Workflow service.
package duoworkflow

import (
	"context"
	"crypto/tls"
	"fmt"
	"time"

	grpc_prometheus "github.com/grpc-ecosystem/go-grpc-prometheus"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/keepalive"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"
	"google.golang.org/grpc"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/version"

	grpccorrelation "gitlab.com/gitlab-org/labkit/correlation/grpc"
	grpctracing "gitlab.com/gitlab-org/labkit/tracing/grpc"
)

// MaxMessageSize is the maximum size of messages that can be sent or received (4MB).
const MaxMessageSize = 4 * 1024 * 1024 // 4MB

// ErrServerUnavailable is returned when the workflow server cannot be reached.
var ErrServerUnavailable = fmt.Errorf("server is unavailable")

// Client is a gRPC client for the Duo Workflow service.
type Client struct {
	grpcConn   *grpc.ClientConn
	grpcClient pb.DuoWorkflowClient
	headers    map[string]string
}

// NewClient creates a new Duo Workflow client with the specified server address,
// headers, and security settings.
func NewClient(serverURI string, headers map[string]string, secure bool, userAgent string) (*Client, error) {
	opts := []grpc.DialOption{
		grpc.WithKeepaliveParams(keepalive.ClientParameters{
			Time:                20 * time.Second, // send pings every 20 seconds if there is no activity
			PermitWithoutStream: true,
		}),
		grpc.WithChainStreamInterceptor(
			grpctracing.StreamClientTracingInterceptor(),
			grpc_prometheus.StreamClientInterceptor,
			grpccorrelation.StreamClientCorrelationInterceptor(
				grpccorrelation.WithClientName("gitlab-duo-workflow"),
			),
		),
		grpc.WithUserAgent(fmt.Sprintf("%s %s", userAgent, version.GetUserAgentShort())),
	}

	if secure {
		opts = append(opts, grpc.WithTransportCredentials(credentials.NewTLS(&tls.Config{})))
	} else {
		opts = append(opts, grpc.WithTransportCredentials(insecure.NewCredentials()))
	}

	// Configured based on https://grpc.io/docs/guides/service-config/
	serviceConfig := `{
	    "methodConfig": [{
	        "name": [{"service": "DuoWorkflow"}],
	        "retryPolicy": {
	            "maxAttempts": 4,
	            "initialBackoff": "0.1s",
	            "maxBackoff": "1s",
	            "backoffMultiplier": 2,
	            "retryableStatusCodes": [ "UNAVAILABLE" ]
	        }
	    }]
	}`

	callOptions := grpc.WithDefaultCallOptions(grpc.MaxCallRecvMsgSize(MaxMessageSize), grpc.MaxCallSendMsgSize(MaxMessageSize))
	opts = append(opts, grpc.WithDefaultServiceConfig(serviceConfig), callOptions)

	conn, err := grpc.NewClient(serverURI, opts...)
	if err != nil {
		return nil, err
	}

	return &Client{
		grpcConn:   conn,
		grpcClient: pb.NewDuoWorkflowClient(conn),
		headers:    headers,
	}, nil
}

// ExecuteWorkflow initiates a new workflow execution stream with the server.
func (c *Client) ExecuteWorkflow(ctx context.Context) (pb.DuoWorkflow_ExecuteWorkflowClient, error) {
	ctx = metadata.NewOutgoingContext(ctx, metadata.New(c.headers))

	stream, err := c.grpcClient.ExecuteWorkflow(ctx)
	if err != nil {
		st, ok := status.FromError(err)
		if ok && st.Code() == codes.Unavailable {
			return nil, ErrServerUnavailable
		}
		return nil, err
	}

	return stream, nil
}

// Close terminates the connection to the workflow server.
func (c *Client) Close() error {
	return c.grpcConn.Close()
}

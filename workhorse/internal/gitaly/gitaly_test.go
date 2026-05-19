package gitaly

import (
	"context"
	"os"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"

	gitalyclient "gitlab.com/gitlab-org/gitaly/v18/client"
	grpccorrelation "gitlab.com/gitlab-org/labkit/correlation/grpc"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

func TestMain(m *testing.M) {
	InitializeSidechannelRegistry(logrus.StandardLogger())
	os.Exit(m.Run())
}

func TestNewSmartHTTPClient(t *testing.T) {
	ctx, client, err := NewSmartHTTPClient(
		context.Background(),
		serverFixture(),
	)
	require.NoError(t, err)
	testOutgoingMetadata(ctx, t)
	require.NotNil(t, client.sidechannelRegistry)
}

func TestNewBlobClient(t *testing.T) {
	ctx, _, err := NewBlobClient(
		context.Background(),
		serverFixture(),
	)
	require.NoError(t, err)
	testOutgoingMetadata(ctx, t)
}

func TestNewRepositoryClient(t *testing.T) {
	ctx, _, err := NewRepositoryClient(
		context.Background(),
		serverFixture(),
	)

	require.NoError(t, err)
	testOutgoingMetadata(ctx, t)
}

func TestNewDiffClient(t *testing.T) {
	ctx, _, err := NewDiffClient(
		context.Background(),
		serverFixture(),
	)
	require.NoError(t, err)
	testOutgoingMetadata(ctx, t)
}

func TestNewConnection(t *testing.T) {
	conn, err := NewConnection(serverFixture())
	require.NotNil(t, conn)
	require.NoError(t, err)
}

func TestSidechannel(t *testing.T) {
	sidechannel, err := Sidechannel()
	require.Equal(t, sidechannelRegistry, sidechannel)
	require.NoError(t, err)
}

func TestSidechannelNotInitialized(t *testing.T) {
	sidechannelRegistry = nil

	sidechannel, err := Sidechannel()
	require.Nil(t, sidechannel)
	require.ErrorContains(t, err, "sidechannel is not initialized")
}

func testOutgoingMetadata(ctx context.Context, t *testing.T) {
	t.Helper()
	md, ok := metadata.FromOutgoingContext(ctx)
	require.True(t, ok, "get metadata from context")

	require.Equal(t, metadata.MD{"username": {"janedoe"}}, md)
}

func serverFixture() api.GitalyServer {
	return api.GitalyServer{
		Address:      "tcp://localhost:123",
		CallMetadata: map[string]string{"username": "janedoe"},
	}
}

func TestWithOutgoingMetadata(t *testing.T) {
	ctx := withOutgoingMetadata(context.Background(), api.GitalyServer{
		CallMetadata: map[string]string{
			"gitaly-feature-abc":    "true",
			"gitaly-featuregarbage": "blocked",
			"bad-header":            "blocked",
			"user_id":               "234",
			"username":              "janedoe",
			"remote_ip":             "1.2.3.4",
		},
	})

	md, ok := metadata.FromOutgoingContext(ctx)
	require.True(t, ok)

	require.Equal(t, metadata.MD{
		"gitaly-feature-abc": {"true"},
		"user_id":            {"234"},
		"username":           {"janedoe"},
		"remote_ip":          {"1.2.3.4"},
	}, md)
}

func TestWithOutgoingMetadataClientName(t *testing.T) {
	ctx := withOutgoingMetadata(context.Background(), api.GitalyServer{
		CallMetadata: map[string]string{
			"client_name": "gkg-indexer",
			"user_id":     "234",
		},
	})

	md, ok := metadata.FromOutgoingContext(ctx)
	require.True(t, ok)

	// client_name is rewritten onto Labkit's canonical header so that Gitaly's
	// correlation-aware extractor surfaces it as grpc.meta.client_name instead
	// of falling back to the raw "client_name" key (which Labkit's per-call
	// "gitlab-workhorse" value hides).
	require.Equal(t, []string{"gkg-indexer"}, md.Get("x-gitlab-client-name"))
	require.Empty(t, md.Get("client_name"),
		"raw client_name key must not be set when x-gitlab-client-name carries the value")
	require.Equal(t, []string{"234"}, md.Get("user_id"))
}

// TestClientNamePrecedenceAfterLabkitInterceptor guards the end-to-end contract
// with Gitaly: Workhorse dials Gitaly through a gRPC client interceptor chain
// that includes Labkit's UnaryClientCorrelationInterceptor, which *appends*
// "x-gitlab-client-name=gitlab-workhorse" to every outgoing call. Gitaly's
// request-info middleware extracts the client name via Labkit's server
// interceptor, which consumes the first value for the header. This test
// verifies that when Rails provides a per-call client_name in CallMetadata the
// final outgoing metadata places the Rails-supplied value first, so Gitaly
// attributes the call to e.g. "gkg-indexer" instead of "gitlab-workhorse".
//
// This is the regression test for
// https://gitlab.com/gitlab-org/gitlab/-/merge_requests/233076: the original
// implementation passed the value under the "client_name" md key, which Gitaly
// only reads as a fallback and therefore the Labkit-appended
// "gitlab-workhorse" value always won.
func TestClientNamePrecedenceAfterLabkitInterceptor(t *testing.T) {
	ctx := withOutgoingMetadata(context.Background(), api.GitalyServer{
		CallMetadata: map[string]string{
			"client_name": "gkg-indexer",
		},
	})

	// Invoke the same Labkit client interceptor newConnection installs on the
	// Gitaly dial. It wraps the invoker, so we capture the context the server
	// would observe (converted from outgoing to incoming to mirror the wire).
	interceptor := grpccorrelation.UnaryClientCorrelationInterceptor(
		grpccorrelation.WithClientName("gitlab-workhorse"),
	)

	var observed metadata.MD
	invoker := func(ctx context.Context, _ string, _, _ any, _ *grpc.ClientConn, _ ...grpc.CallOption) error {
		md, ok := metadata.FromOutgoingContext(ctx)
		require.True(t, ok, "interceptor must leave outgoing metadata intact")
		observed = md
		return nil
	}

	err := interceptor(ctx, "/test/Method", nil, nil, nil, invoker)
	require.NoError(t, err)

	// Gitaly's server-side Labkit interceptor reads md.Get(...)[0]; the
	// Rails-supplied value must appear before the connection-wide default.
	values := observed.Get("x-gitlab-client-name")
	require.Equal(t, []string{"gkg-indexer", "gitlab-workhorse"}, values,
		"Rails-supplied client_name must be the first value so Gitaly attributes the call correctly")
}

func TestCorrelationIDPropagation(t *testing.T) {
	correlationID := "test-correlation-123"

	ctx := context.WithValue(context.Background(), GitalyCorrelationIDKey, correlationID)

	server := api.GitalyServer{
		Address: "tcp://example.com:9999",
		Token:   "secret-token",
		CallMetadata: map[string]string{
			"user_id": "123",
		},
	}

	resultCtx := withOutgoingMetadata(ctx, server)

	md, ok := metadata.FromOutgoingContext(resultCtx)
	require.True(t, ok, "outgoing metadata should be present")

	correlationValues := md.Get("x-gitlab-correlation-id")
	require.Len(t, correlationValues, 1, "should have exactly one correlation ID")
	require.Equal(t, correlationID, correlationValues[0], "correlation ID should match")

	userIDValues := md.Get("user_id")
	require.Len(t, userIDValues, 1, "should preserve other metadata")
	require.Equal(t, "123", userIDValues[0], "user_id should be preserved")
}

func TestCorrelationIDPropagationWithoutCorrelationID(t *testing.T) {
	ctx := context.Background()

	server := api.GitalyServer{
		Address: "tcp://example.com:9999",
		Token:   "secret-token",
		CallMetadata: map[string]string{
			"user_id": "123",
		},
	}

	resultCtx := withOutgoingMetadata(ctx, server)

	md, ok := metadata.FromOutgoingContext(resultCtx)
	require.True(t, ok, "outgoing metadata should be present")

	correlationValues := md.Get("x-gitlab-correlation-id")
	require.Empty(t, correlationValues, "should have no correlation ID when none provided")

	userIDValues := md.Get("user_id")
	require.Len(t, userIDValues, 1, "should still preserve other metadata")
	require.Equal(t, "123", userIDValues[0], "user_id should be preserved")
}

func TestParseRetryPolicy(t *testing.T) {
	tests := []struct {
		name         string
		callMetadata map[string]string
		expectNil    bool
		validate     func(t *testing.T, policy *gitalyclient.RetryPolicy)
	}{
		{
			name:         "no retry_config",
			callMetadata: map[string]string{"username": "janedoe"},
			expectNil:    true,
		},
		{
			name:         "empty retry_config",
			callMetadata: map[string]string{"retry_config": ""},
			expectNil:    true,
		},
		{
			name:         "invalid JSON retry_config",
			callMetadata: map[string]string{"retry_config": "not-json"},
			expectNil:    true,
		},
		{
			name: "valid retry_config",
			callMetadata: map[string]string{
				"retry_config": `{"maxAttempts":4,"initialBackoff":"0.4s","maxBackoff":"1.4s","backoffMultiplier":2,"retryableStatusCodes":["UNAVAILABLE","ABORTED"]}`,
			},
			expectNil: false,
			validate: func(t *testing.T, policy *gitalyclient.RetryPolicy) {
				require.Equal(t, uint32(4), policy.GetMaxAttempts())
				require.Equal(t, int64(0), policy.GetInitialBackoff().GetSeconds())
				require.Equal(t, int32(400000000), policy.GetInitialBackoff().GetNanos())
				require.Equal(t, int64(1), policy.GetMaxBackoff().GetSeconds())
				require.Equal(t, int32(400000000), policy.GetMaxBackoff().GetNanos())
				require.InEpsilon(t, float32(2), policy.GetBackoffMultiplier(), 0.000001)
				require.Contains(t, policy.GetRetryableStatusCodes(), "UNAVAILABLE")
				require.Contains(t, policy.GetRetryableStatusCodes(), "ABORTED")
			},
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			server := api.GitalyServer{
				Address:      "tcp://localhost:123",
				CallMetadata: tt.callMetadata,
			}

			policy := parseRetryPolicy(server)

			if tt.expectNil {
				require.Nil(t, policy)
			} else {
				require.NotNil(t, policy)
				if tt.validate != nil {
					tt.validate(t, policy)
				}
			}
		})
	}
}

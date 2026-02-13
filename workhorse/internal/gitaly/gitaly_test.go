package gitaly

import (
	"context"
	"os"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/metadata"

	gitalyclient "gitlab.com/gitlab-org/gitaly/v18/client"

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

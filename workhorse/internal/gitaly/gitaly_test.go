package gitaly

import (
	"context"
	"os"
	"testing"

	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/metadata"

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

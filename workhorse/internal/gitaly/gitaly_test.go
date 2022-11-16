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
		WithFeatures(features()),
		WithLoggingMetadata(&api.Response{
			GL_USERNAME: "gl_username",
			GL_ID:       "gl_id",
			RemoteIp:    "1.2.3.4",
		}),
	)
	require.NoError(t, err)
	testOutgoingMetadata(t, ctx)
	testOutgoingIDAndUsername(t, ctx)
	testOutgoingRemoteIP(t, ctx)
	require.NotNil(t, client.sidechannelRegistry)
}

func TestNewBlobClient(t *testing.T) {
	ctx, _, err := NewBlobClient(
		context.Background(),
		serverFixture(),
		WithFeatures(features()),
	)
	require.NoError(t, err)
	testOutgoingMetadata(t, ctx)
}

func TestNewRepositoryClient(t *testing.T) {
	ctx, _, err := NewRepositoryClient(
		context.Background(),
		serverFixture(),
		WithFeatures(features()),
	)

	require.NoError(t, err)
	testOutgoingMetadata(t, ctx)
}

func TestNewNamespaceClient(t *testing.T) {
	ctx, _, err := NewNamespaceClient(
		context.Background(),
		serverFixture(),
		WithFeatures(features()),
	)
	require.NoError(t, err)
	testOutgoingMetadata(t, ctx)
}

func TestNewDiffClient(t *testing.T) {
	ctx, _, err := NewDiffClient(
		context.Background(),
		serverFixture(),
		WithFeatures(features()),
	)
	require.NoError(t, err)
	testOutgoingMetadata(t, ctx)
}

func testOutgoingMetadata(t *testing.T, ctx context.Context) {
	md, ok := metadata.FromOutgoingContext(ctx)
	require.True(t, ok, "get metadata from context")

	for k, v := range allowedFeatures() {
		actual := md[k]
		require.Len(t, actual, 1, "expect one value for %v", k)
		require.Equal(t, v, actual[0], "value for %v", k)
	}

	for k := range badFeatureMetadata() {
		require.Empty(t, md[k], "value for bad key %v", k)
	}
}

func testOutgoingIDAndUsername(t *testing.T, ctx context.Context) {
	md, ok := metadata.FromOutgoingContext(ctx)
	require.True(t, ok, "get metadata from context")

	require.Equal(t, md["user_id"], []string{"gl_id"})
	require.Equal(t, md["username"], []string{"gl_username"})
}

func testOutgoingRemoteIP(t *testing.T, ctx context.Context) {
	md, ok := metadata.FromOutgoingContext(ctx)
	require.True(t, ok, "get metadata from context")

	require.Equal(t, md["remote_ip"], []string{"1.2.3.4"})
}

func features() map[string]string {
	features := make(map[string]string)
	for k, v := range allowedFeatures() {
		features[k] = v
	}

	for k, v := range badFeatureMetadata() {
		features[k] = v
	}

	return features
}

func serverFixture() api.GitalyServer {
	return api.GitalyServer{Address: "tcp://localhost:123"}
}

func allowedFeatures() map[string]string {
	return map[string]string{
		"gitaly-feature-foo": "bar",
		"gitaly-feature-qux": "baz",
	}
}

func badFeatureMetadata() map[string]string {
	return map[string]string{
		"bad-metadata-1": "bad-value-1",
		"bad-metadata-2": "bad-value-2",
	}
}

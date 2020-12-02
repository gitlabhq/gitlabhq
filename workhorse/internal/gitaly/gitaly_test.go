package gitaly

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
	"google.golang.org/grpc/metadata"
)

func TestNewSmartHTTPClient(t *testing.T) {
	ctx, _, err := NewSmartHTTPClient(context.Background(), serverFixture())
	require.NoError(t, err)
	testOutgoingMetadata(t, ctx)
}

func TestNewBlobClient(t *testing.T) {
	ctx, _, err := NewBlobClient(context.Background(), serverFixture())
	require.NoError(t, err)
	testOutgoingMetadata(t, ctx)
}

func TestNewRepositoryClient(t *testing.T) {
	ctx, _, err := NewRepositoryClient(context.Background(), serverFixture())
	require.NoError(t, err)
	testOutgoingMetadata(t, ctx)
}

func TestNewNamespaceClient(t *testing.T) {
	ctx, _, err := NewNamespaceClient(context.Background(), serverFixture())
	require.NoError(t, err)
	testOutgoingMetadata(t, ctx)
}

func TestNewDiffClient(t *testing.T) {
	ctx, _, err := NewDiffClient(context.Background(), serverFixture())
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

func serverFixture() Server {
	features := make(map[string]string)
	for k, v := range allowedFeatures() {
		features[k] = v
	}
	for k, v := range badFeatureMetadata() {
		features[k] = v
	}

	return Server{Address: "tcp://localhost:123", Features: features}
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

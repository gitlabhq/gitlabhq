package objectstore

import (
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

func TestS3ClientSetup(t *testing.T) {
	resetS3Clients()

	credentials := config.S3Credentials{}
	cfg := config.S3Config{Region: "us-west-1", PathStyle: true}

	client, err := setupS3Client(credentials, cfg)
	require.NoError(t, err)

	options := client.Options()
	require.Nil(t, options.BaseEndpoint)
	require.Equal(t, "us-west-1", options.Region)
	require.True(t, options.UsePathStyle)

	clientCache.Lock()
	require.Len(t, clientCache.clients, 1)
	clientCache.Unlock()

	anotherConfig := cfg
	_, err = setupS3Client(credentials, anotherConfig)
	require.NoError(t, err)

	clientCache.Lock()
	require.Len(t, clientCache.clients, 1)
	clientCache.Unlock()
}

func TestS3ClientEndpointSetup(t *testing.T) {
	resetS3Clients()

	credentials := config.S3Credentials{}
	const customS3Endpoint = "https://example.com"
	const region = "us-west-2"
	cfg := config.S3Config{Region: region, PathStyle: true, Endpoint: customS3Endpoint}

	client, err := setupS3Client(credentials, cfg)
	require.NoError(t, err)

	options := client.Options()
	require.Equal(t, customS3Endpoint, *options.BaseEndpoint)
	require.Equal(t, region, options.Region)
}

func TestS3ClientExpiry(t *testing.T) {
	resetS3Clients()

	credentials := config.S3Credentials{}
	cfg := config.S3Config{Region: "us-west-1", PathStyle: true}

	client, err := setupS3Client(credentials, cfg)
	require.NoError(t, err)

	options := client.Options()
	require.Equal(t, "us-west-1", options.Region)
	require.True(t, options.UsePathStyle)

	firstClient, ok := getS3Client(cfg)
	require.True(t, ok)
	require.False(t, firstClient.isExpired())

	firstClient.expiry = time.Now().Add(-1 * time.Second)
	require.True(t, firstClient.isExpired())

	_, err = setupS3Client(credentials, cfg)
	require.NoError(t, err)

	nextClient, ok := getS3Client(cfg)
	require.True(t, ok)
	require.False(t, nextClient.isExpired())
}

func resetS3Clients() {
	clientCache.Lock()
	defer clientCache.Unlock()
	clientCache.clients = make(map[config.S3Config]*s3Client)
}

func getS3Client(cfg config.S3Config) (*s3Client, bool) {
	clientCache.Lock()
	defer clientCache.Unlock()
	session, ok := clientCache.clients[cfg]
	return session, ok
}

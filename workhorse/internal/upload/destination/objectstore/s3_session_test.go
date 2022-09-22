package objectstore

import (
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/endpoints"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

func TestS3SessionSetup(t *testing.T) {
	resetS3Sessions()

	credentials := config.S3Credentials{}
	cfg := config.S3Config{Region: "us-west-1", PathStyle: true}

	sess, err := setupS3Session(credentials, cfg)
	require.NoError(t, err)

	s3Config := sess.ClientConfig(endpoints.S3ServiceID)
	require.Equal(t, "https://s3.us-west-1.amazonaws.com", s3Config.Endpoint)
	require.Equal(t, "us-west-1", s3Config.SigningRegion)
	require.True(t, aws.BoolValue(sess.Config.S3ForcePathStyle))

	require.Equal(t, len(sessionCache.sessions), 1)
	anotherConfig := cfg
	_, err = setupS3Session(credentials, anotherConfig)
	require.NoError(t, err)
	require.Equal(t, len(sessionCache.sessions), 1)
}

func TestS3SessionEndpointSetup(t *testing.T) {
	resetS3Sessions()

	credentials := config.S3Credentials{}
	const customS3Endpoint = "https://example.com"
	const region = "us-west-2"
	cfg := config.S3Config{Region: region, PathStyle: true, Endpoint: customS3Endpoint}

	sess, err := setupS3Session(credentials, cfg)
	require.NoError(t, err)

	// ClientConfig is what is ultimately used by an S3 client
	s3Config := sess.ClientConfig(endpoints.S3ServiceID)
	require.Equal(t, customS3Endpoint, s3Config.Endpoint)
	require.Equal(t, region, s3Config.SigningRegion)

	stsConfig := sess.ClientConfig(endpoints.StsServiceID)
	require.Equal(t, "https://sts.amazonaws.com", stsConfig.Endpoint, "STS should use default endpoint")
}

func TestS3SessionExpiry(t *testing.T) {
	resetS3Sessions()

	credentials := config.S3Credentials{}
	cfg := config.S3Config{Region: "us-west-1", PathStyle: true}

	sess, err := setupS3Session(credentials, cfg)
	require.NoError(t, err)

	require.Equal(t, aws.StringValue(sess.Config.Region), "us-west-1")
	require.True(t, aws.BoolValue(sess.Config.S3ForcePathStyle))

	firstSession, ok := sessionCache.sessions[cfg]
	require.True(t, ok)
	require.False(t, firstSession.isExpired())

	firstSession.expiry = time.Now().Add(-1 * time.Second)
	require.True(t, firstSession.isExpired())

	_, err = setupS3Session(credentials, cfg)
	require.NoError(t, err)

	nextSession, ok := sessionCache.sessions[cfg]
	require.True(t, ok)
	require.False(t, nextSession.isExpired())
}

func resetS3Sessions() {
	sessionCache.Lock()
	defer sessionCache.Unlock()
	sessionCache.sessions = make(map[config.S3Config]*s3Session)
}

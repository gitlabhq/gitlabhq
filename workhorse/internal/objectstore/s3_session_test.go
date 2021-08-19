package objectstore

import (
	"testing"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

func TestS3SessionSetup(t *testing.T) {
	credentials := config.S3Credentials{}
	cfg := config.S3Config{Region: "us-west-1", PathStyle: true}

	sess, err := setupS3Session(credentials, cfg)
	require.NoError(t, err)

	require.Equal(t, aws.StringValue(sess.Config.Region), "us-west-1")
	require.True(t, aws.BoolValue(sess.Config.S3ForcePathStyle))

	require.Equal(t, len(sessionCache.sessions), 1)
	anotherConfig := cfg
	_, err = setupS3Session(credentials, anotherConfig)
	require.NoError(t, err)
	require.Equal(t, len(sessionCache.sessions), 1)

	ResetS3Session(cfg)
}

func TestS3SessionExpiry(t *testing.T) {
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

	ResetS3Session(cfg)
}

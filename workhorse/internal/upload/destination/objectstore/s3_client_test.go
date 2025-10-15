package objectstore

import (
	"os"
	"testing"
	"time"

	"github.com/aws/aws-sdk-go-v2/aws"
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

func TestGetRequestChecksumCalculation(t *testing.T) {
	tests := []struct {
		name     string
		envValue string
		expected aws.RequestChecksumCalculation
	}{
		{
			name:     "default when env var not set",
			envValue: "",
			expected: aws.RequestChecksumCalculationWhenRequired,
		},
		{
			name:     "when_supported",
			envValue: "when_supported",
			expected: aws.RequestChecksumCalculationWhenSupported,
		},
		{
			name:     "when_required",
			envValue: "when_required",
			expected: aws.RequestChecksumCalculationWhenRequired,
		},
		{
			name:     "case insensitive when_supported",
			envValue: "WHEN_SUPPORTED",
			expected: aws.RequestChecksumCalculationWhenSupported,
		},
		{
			name:     "case insensitive when_required",
			envValue: "WHEN_REQUIRED",
			expected: aws.RequestChecksumCalculationWhenRequired,
		},
		{
			name:     "mixed case when_supported",
			envValue: "When_Supported",
			expected: aws.RequestChecksumCalculationWhenSupported,
		},
		{
			name:     "invalid value defaults to when_required",
			envValue: "invalid_value",
			expected: aws.RequestChecksumCalculationWhenRequired,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			// Save original env var
			original := os.Getenv("AWS_REQUEST_CHECKSUM_CALCULATION")
			defer func() {
				if original == "" {
					os.Unsetenv("AWS_REQUEST_CHECKSUM_CALCULATION")
				} else {
					os.Setenv("AWS_REQUEST_CHECKSUM_CALCULATION", original)
				}
			}()

			// Set test env var
			if tt.envValue == "" {
				os.Unsetenv("AWS_REQUEST_CHECKSUM_CALCULATION")
			} else {
				os.Setenv("AWS_REQUEST_CHECKSUM_CALCULATION", tt.envValue)
			}

			actual := getRequestChecksumCalculation()
			require.Equal(t, tt.expected, actual)
		})
	}
}

func TestGetResponseChecksumCalculation(t *testing.T) {
	tests := []struct {
		name     string
		envValue string
		expected aws.ResponseChecksumValidation
	}{
		{
			name:     "default when env var not set",
			envValue: "",
			expected: aws.ResponseChecksumValidationWhenRequired,
		},
		{
			name:     "when_supported",
			envValue: "when_supported",
			expected: aws.ResponseChecksumValidationWhenSupported,
		},
		{
			name:     "when_required",
			envValue: "when_required",
			expected: aws.ResponseChecksumValidationWhenRequired,
		},
		{
			name:     "case insensitive when_supported",
			envValue: "WHEN_SUPPORTED",
			expected: aws.ResponseChecksumValidationWhenSupported,
		},
		{
			name:     "case insensitive when_required",
			envValue: "WHEN_REQUIRED",
			expected: aws.ResponseChecksumValidationWhenRequired,
		},
		{
			name:     "mixed case when_supported",
			envValue: "When_Supported",
			expected: aws.ResponseChecksumValidationWhenSupported,
		},
		{
			name:     "invalid value defaults to when_required",
			envValue: "invalid_value",
			expected: aws.ResponseChecksumValidationWhenRequired,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			original := os.Getenv("AWS_RESPONSE_CHECKSUM_VALIDATION")
			defer func() {
				if original == "" {
					os.Unsetenv("AWS_RESPONSE_CHECKSUM_VALIDATION")
				} else {
					os.Setenv("AWS_RESPONSE_CHECKSUM_VALIDATION", original)
				}
			}()

			if tt.envValue == "" {
				os.Unsetenv("AWS_RESPONSE_CHECKSUM_VALIDATION")
			} else {
				os.Setenv("AWS_RESPONSE_CHECKSUM_VALIDATION", tt.envValue)
			}

			actual := getResponseChecksumCalculation()
			require.Equal(t, tt.expected, actual)
		})
	}
}

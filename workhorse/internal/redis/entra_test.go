package redis

import (
	"net/url"
	"testing"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// Constructing a real managed-identity or default-azure provider eagerly
// acquires a token from the cloud, so only the routing decisions that do not
// reach out to the provider are unit tested here. Provider construction itself
// is exercised in an environment with connectivity.
func TestCredentialsProvider(t *testing.T) {
	t.Run("returns an error for an unknown provider", func(t *testing.T) {
		cp := &config.RedisCredentialsProvider{Provider: "bogus"}

		_, err := credentialsProvider(cp)
		require.ErrorContains(t, err, "unknown Redis credentials_provider")
	})

	t.Run("returns an error for an unknown azure auth_type", func(t *testing.T) {
		cp := &config.RedisCredentialsProvider{
			Provider: "azure",
			Azure:    &config.RedisAzureConfig{AuthType: "bogus"},
		}

		_, err := credentialsProvider(cp)
		require.ErrorContains(t, err, "unknown Redis azure auth_type")
	})
}

func TestConfigureRedisRejectsCredentialsProviderWithoutTLS(t *testing.T) {
	u, err := url.Parse("redis://localhost:6379")
	require.NoError(t, err)

	cfg := &config.RedisConfig{
		URL:                 config.TomlURL{URL: *u},
		CredentialsProvider: &config.RedisCredentialsProvider{Provider: "azure"},
	}

	_, err = configureRedis(cfg)
	require.ErrorContains(t, err, "credentials_provider requires TLS")
}

func TestConfigureSentinelRejectsCredentialsProvider(t *testing.T) {
	cfg := &config.Config{
		Redis: &config.RedisConfig{
			CredentialsProvider: &config.RedisCredentialsProvider{Provider: "azure"},
		},
	}

	_, err := configureSentinel(cfg)
	require.ErrorContains(t, err, "not supported with Redis Sentinel")
}

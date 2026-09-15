package redis

import (
	"fmt"

	"github.com/redis/go-redis/v9/auth"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// credentialsProvider builds a streaming credentials provider for passwordless
// Redis authentication from the configured cloud provider, refreshing the
// token on live connections before it expires. It dispatches on the provider
// name so additional clouds (for example AWS or Google) can be added alongside
// Azure.
func credentialsProvider(cp *config.RedisCredentialsProvider) (auth.StreamingCredentialsProvider, error) {
	switch cp.Provider {
	case "azure":
		return azureCredentialsProvider(cp.Azure)
	default:
		return nil, fmt.Errorf("unknown Redis credentials_provider: %q", cp.Provider)
	}
}

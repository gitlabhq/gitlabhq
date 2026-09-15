package redis

import (
	"fmt"

	entraid "github.com/redis/go-redis-entraid"
	"github.com/redis/go-redis-entraid/identity"
	"github.com/redis/go-redis/v9/auth"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

// defaultRedisEntraScope is the OAuth scope for Azure Cache for Redis.
const defaultRedisEntraScope = "https://redis.azure.com/.default"

// azureCredentialsProvider builds a streaming credentials provider that
// authenticates to Azure Cache for Redis with a Microsoft Entra token and
// refreshes it on live connections before it expires.
func azureCredentialsProvider(azure *config.RedisAzureConfig) (auth.StreamingCredentialsProvider, error) {
	// A bare `provider = "azure"` (no [azure] block) means a system-assigned
	// managed identity with the default scope.
	if azure == nil {
		azure = &config.RedisAzureConfig{}
	}

	scopes := []string{defaultRedisEntraScope}
	if azure.Scope != "" {
		scopes = []string{azure.Scope}
	}

	switch azure.AuthType {
	case "", "default":
		return entraid.NewDefaultAzureCredentialsProvider(entraid.DefaultAzureCredentialsProviderOptions{
			DefaultAzureIdentityProviderOptions: identity.DefaultAzureIdentityProviderOptions{
				Scopes: scopes,
			},
		})
	case "managed_identity":
		return managedIdentityProvider(azure, scopes)
	default:
		return nil, fmt.Errorf("unknown Redis azure auth_type: %q", azure.AuthType)
	}
}

func managedIdentityProvider(azure *config.RedisAzureConfig, scopes []string) (auth.StreamingCredentialsProvider, error) {
	// An explicit ObjectID selects a user-assigned identity; otherwise the
	// system-assigned identity is used.
	miType := identity.SystemAssignedIdentity
	if azure.ObjectID != "" {
		miType = identity.UserAssignedObjectID
	}

	return entraid.NewManagedIdentityCredentialsProvider(entraid.ManagedIdentityCredentialsProviderOptions{
		ManagedIdentityProviderOptions: identity.ManagedIdentityProviderOptions{
			ManagedIdentityType:  miType,
			UserAssignedObjectID: azure.ObjectID,
			Scopes:               scopes,
		},
	})
}

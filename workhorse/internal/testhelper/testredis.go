package testhelper

import (
	"context"
	"os"
	"path"
	"testing"

	redis "github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	configRedis "gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
)

// SetupRedis configures an isolated Redis client for tests.
// Each test package must pass a unique db number to prevent cross-package
// interference when Go runs test packages in parallel.
// The database is flushed and the client is closed automatically when
// the test completes.
func SetupRedis(t *testing.T, db int) *redis.Client {
	t.Helper()

	buf, err := os.ReadFile(path.Join(RootDir(), "config.toml"))
	require.NoError(t, err)

	cfg, err := config.LoadConfig(string(buf))
	require.NoError(t, err)

	cfg.Redis.DB = &db

	rdb, err := configRedis.Configure(cfg)
	require.NoError(t, err)

	t.Cleanup(func() {
		rdb.FlushDB(context.Background()) //nolint:errcheck // lint:allow context.Background
		require.NoError(t, rdb.Close())
	})

	return rdb
}

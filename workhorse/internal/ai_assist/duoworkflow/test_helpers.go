package duoworkflow

import (
	"context"
	"os"
	"testing"

	redis "github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	redisInternal "gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
)

func initRdb(t *testing.T) *redis.Client {
	buf, err := os.ReadFile("../../../config.toml")
	require.NoError(t, err)
	cfg, err := config.LoadConfig(string(buf))
	require.NoError(t, err)
	rdb, err := redisInternal.Configure(cfg)
	require.NoError(t, err)
	t.Cleanup(func() {
		clearLocks(t, rdb)
		require.NoError(t, rdb.Close())
	})
	clearLocks(t, rdb)
	return rdb
}

// We want to clear the locks between tests to avoid test pollution
func clearLocks(t *testing.T, rdb *redis.Client) {
	keys, err := rdb.Keys(context.Background(), workflowLockPrefix+"*").Result() // lint:allow context.Background
	require.NoError(t, err)
	if len(keys) > 0 {
		_, err = rdb.Del(context.Background(), keys...).Result() // lint:allow context.Background
		require.NoError(t, err)
	}
}

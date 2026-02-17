package ratelimitcache

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestBlockCache_IsBlocked_NotBlocked(t *testing.T) {
	rdb := InitRdb(t)
	cache := newBlockCache(rdb)
	ctx := context.Background()

	blockedUntil, blocked := cache.isBlocked(ctx, "user-not-blocked")

	assert.False(t, blocked)
	assert.True(t, blockedUntil.IsZero())
}

func TestBlockCache_SetBlock_ThenIsBlocked(t *testing.T) {
	rdb := InitRdb(t)
	cache := newBlockCache(rdb)
	ctx := context.Background()

	userKey := "user-set-block-1"
	blockedUntil := time.Now().Add(60 * time.Second)

	cache.setBlock(ctx, userKey, blockedUntil)

	gotBlockedUntil, blocked := cache.isBlocked(ctx, userKey)

	assert.True(t, blocked)
	assert.WithinDuration(t, blockedUntil, gotBlockedUntil, time.Second)
}

func TestBlockCache_ExpiredBlock_NotBlocked(t *testing.T) {
	rdb := InitRdb(t)
	cache := newBlockCache(rdb)
	ctx := context.Background()

	userKey := "user-expired"
	blockedUntil := time.Now().Add(-10 * time.Second)

	cache.setBlock(ctx, userKey, blockedUntil)

	_, blocked := cache.isBlocked(ctx, userKey)

	assert.False(t, blocked)
}

func TestBlockCache_LocalCacheHit(t *testing.T) {
	rdb := InitRdb(t)
	cache := newBlockCache(rdb)
	ctx := context.Background()

	userKey := "user-local-hit-1"
	blockedUntil := time.Now().Add(60 * time.Second)

	cache.local.setBlock(userKey, blockedUntil)

	gotBlockedUntil, blocked := cache.isBlocked(ctx, userKey)

	assert.True(t, blocked)
	assert.WithinDuration(t, blockedUntil, gotBlockedUntil, time.Second)
}

func TestBlockCache_RedisFallback(t *testing.T) {
	rdb := InitRdb(t)
	cache := newBlockCache(rdb)
	ctx := context.Background()

	userKey := "user-redis-fallback"
	blockedUntil := time.Now().Add(60 * time.Second)

	// Set block in Redis directly, bypassing local cache
	ttl := time.Until(blockedUntil)
	err := rdb.Set(ctx, redisKey(userKey), blockedUntil.Unix(), ttl).Err()
	require.NoError(t, err)

	gotBlockedUntil, blocked := cache.isBlocked(ctx, userKey)

	assert.True(t, blocked)
	assert.WithinDuration(t, blockedUntil, gotBlockedUntil, time.Second)

	// Verify local cache was populated
	localBlockedUntil, localBlocked := cache.local.isBlocked(userKey)
	assert.True(t, localBlocked)
	assert.WithinDuration(t, blockedUntil, localBlockedUntil, time.Second)
}

func TestBlockCache_LocalCacheExpiration(t *testing.T) {
	rdb := InitRdb(t)
	cache := newBlockCache(rdb)
	ctx := context.Background()

	userKey := "user-local-expired"
	blockedUntil := time.Now().Add(-10 * time.Second)

	cache.local.setBlock(userKey, blockedUntil)

	_, blocked := cache.isBlocked(ctx, userKey)

	assert.False(t, blocked)
}

func TestBlockCache_SetBlock_PopulatesLocalCache(t *testing.T) {
	rdb := InitRdb(t)
	cache := newBlockCache(rdb)
	ctx := context.Background()

	userKey := "user-set-local"
	blockedUntil := time.Now().Add(60 * time.Second)

	cache.setBlock(ctx, userKey, blockedUntil)

	localBlockedUntil, localBlocked := cache.local.isBlocked(userKey)
	assert.True(t, localBlocked)
	assert.WithinDuration(t, blockedUntil, localBlockedUntil, time.Second)
}

func TestRedisKey(t *testing.T) {
	assert.Equal(t, "blockcache:user-123", redisKey("user-123"))
}

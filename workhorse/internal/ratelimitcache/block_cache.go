package ratelimitcache

import (
	"context"
	"errors"
	"time"

	redis "github.com/redis/go-redis/v9"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

const (
	redisKeyPrefix        = "blockcache:"
	redisOperationTimeout = 100 * time.Millisecond
)

// blockCache provides a two-tier write-through cache for user blocks.
type blockCache struct {
	redis *redis.Client
	local *localCache
}

// newBlockCache creates a new blockCache with the given Redis client.
func newBlockCache(client *redis.Client) *blockCache {
	return &blockCache{
		redis: client,
		local: newLocalCache(),
	}
}

// isBlocked checks if a user is blocked. Checks local cache first, then Redis.
// Returns (blockedUntil, true) if blocked and not expired.
// Returns (time.Time{}, false) if not blocked, expired, or on error.
func (s *blockCache) isBlocked(ctx context.Context, userKey string) (time.Time, bool) {
	// Check local cache first
	if blockedUntil, blocked := s.local.isBlocked(userKey); blocked {
		return blockedUntil, true
	}

	// Check Redis
	blockedUntil, blocked := s.isBlockedInRedis(ctx, userKey)
	if blocked {
		// Populate local cache
		s.local.setBlock(userKey, blockedUntil)
		return blockedUntil, true
	}

	return time.Time{}, false
}

// setBlock records that a user is blocked until the specified time.
func (s *blockCache) setBlock(ctx context.Context, userKey string, blockedUntil time.Time) {
	s.local.setBlock(userKey, blockedUntil)

	ttl := time.Until(blockedUntil)
	if ttl <= 0 {
		return
	}

	if ctx.Err() != nil {
		return
	}

	ctx, cancel := context.WithTimeout(ctx, redisOperationTimeout)
	defer cancel()

	err := s.redis.Set(ctx, redisKey(userKey), blockedUntil.Unix(), ttl).Err()
	if err != nil {
		log.WithError(err).Info("blockcache: failed to set block in Redis")
	}
}

func (s *blockCache) isBlockedInRedis(ctx context.Context, userKey string) (time.Time, bool) {
	ctx, cancel := context.WithTimeout(ctx, redisOperationTimeout)
	defer cancel()

	val, err := s.redis.Get(ctx, redisKey(userKey)).Int64()
	if err != nil {
		if !errors.Is(err, redis.Nil) {
			log.WithError(err).Info("blockcache: failed to get block from Redis")
		}
		return time.Time{}, false
	}

	blockedUntil := time.Unix(val, 0)
	if time.Now().After(blockedUntil) {
		return time.Time{}, false
	}

	return blockedUntil, true
}

func redisKey(userKey string) string {
	return redisKeyPrefix + userKey
}

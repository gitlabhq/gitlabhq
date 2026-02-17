package ratelimitcache

import (
	"time"

	lru "github.com/hashicorp/golang-lru/v2"
)

const localCacheMaxSize = 10000

// localCache provides an in-memory LRU cache for user blocks.
type localCache struct {
	blocks *lru.Cache[string, time.Time]
}

// newLocalCache creates a new localCache.
func newLocalCache() *localCache {
	cache, err := lru.New[string, time.Time](localCacheMaxSize)
	if err != nil {
		// This should never happen with a positive localCacheMaxSize
		panic("failed to create LRU cache: " + err.Error())
	}
	return &localCache{
		blocks: cache,
	}
}

// isBlocked checks if a user is blocked in the local cache.
// Returns (blockedUntil, true) if blocked and not expired.
// Returns (time.Time{}, false) if not blocked or expired.
func (c *localCache) isBlocked(userKey string) (time.Time, bool) {
	blockedUntil, exists := c.blocks.Get(userKey)
	if !exists {
		return time.Time{}, false
	}

	if time.Now().After(blockedUntil) {
		c.remove(userKey)
		return time.Time{}, false
	}

	return blockedUntil, true
}

// setBlock records that a user is blocked until the specified time.
func (c *localCache) setBlock(userKey string, blockedUntil time.Time) {
	c.blocks.Add(userKey, blockedUntil)
}

// remove deletes a user from the local cache.
func (c *localCache) remove(userKey string) {
	c.blocks.Remove(userKey)
}

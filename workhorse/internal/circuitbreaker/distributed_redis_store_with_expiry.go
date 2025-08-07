/*
* This is an implementation of the gobreaker.SharedDataStore interface. It is inspired by `gobreaker.RedisStore`,
* with some key differences:
*
* - Initializable with a Redis client instead of an address.
* - Sets the expiry of keys to a constant keyExpiry instead of having no expiry.
* - Manages mutexes with a sync.Map for safer concurrency.
* - To avoid memory consumption issues, enforces a maximum capacity on the map of mutexes
*   by clearing the map when it reaches capacity. Under normal circumstances, we wouldn't expect the map to reach capacity.
* - Adds some additional error handling in the Unlock function.
 */

package circuitbreaker

import (
	"context"
	"errors"
	"fmt"
	"sync"
	"sync/atomic"
	"time"

	redsync "github.com/go-redsync/redsync/v4"
	goredis "github.com/go-redsync/redsync/v4/redis/goredis/v9"
	redis "github.com/redis/go-redis/v9"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

const (
	mutexTimeout = 5 * time.Second
	keyExpiry    = 30 * time.Minute
	capacity     = 10_000
)

// DistributedRedisStoreWithExpiry is an implementation of the gobreaker.SharedDataStore interface
type DistributedRedisStoreWithExpiry struct {
	ctx       context.Context
	client    *redis.Client
	rs        *redsync.Redsync
	mutex     sync.Map
	mutexSize uint32
}

// NewDistributedRedisStoreWithExpiry creates a DistributedRedisStoreWithExpiry given a redis client.
func NewDistributedRedisStoreWithExpiry(client *redis.Client) *DistributedRedisStoreWithExpiry {
	return &DistributedRedisStoreWithExpiry{
		ctx:       context.TODO(), // Usage of TODO indicates that a background context would ideally be passed in from the main function lint:allow context.TODO
		client:    client,
		rs:        redsync.New(goredis.NewPool(client)),
		mutex:     sync.Map{},
		mutexSize: 0,
	}
}

// Lock acquires a distributed lock using the provided name.
func (store *DistributedRedisStoreWithExpiry) Lock(name string) error {
	if value, ok := store.mutex.Load(name); ok {
		mutex := value.(*redsync.Mutex)
		return mutex.Lock()
	}

	mutex := store.newMutex(name)
	return mutex.Lock()
}

// Unlock releases the distributed lock using the provided name.
func (store *DistributedRedisStoreWithExpiry) Unlock(name string) error {
	value, ok := store.mutex.Load(name)
	if !ok {
		return fmt.Errorf("unlock failed: mutex %q not found", name)
	}

	mutex := value.(*redsync.Mutex)
	ok, err := mutex.Unlock()
	if err != nil {
		return fmt.Errorf("unlock failed: %w", err)
	}

	if !ok {
		return fmt.Errorf("unlock failed: mutex %q was not locked", name)
	}

	return nil
}

// GetData retrieves data for the given key.
func (store *DistributedRedisStoreWithExpiry) GetData(name string) ([]byte, error) {
	return store.client.Get(store.ctx, name).Bytes()
}

// SetData stores the provided data for the given key.
func (store *DistributedRedisStoreWithExpiry) SetData(name string, data []byte) error {
	return store.client.Set(store.ctx, name, data, keyExpiry).Err()
}

func (store *DistributedRedisStoreWithExpiry) isUserTracked(gobreakerSharedStateKey string) bool {
	_, err := store.GetData(sharedStateKey(gobreakerSharedStateKey))
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return false
		}

		log.WithError(err).Info("gobreaker: failed to get data from Redis store")
		return false
	}

	return true
}

// newMutex creates a new distributed mutex and stores it in the store.mutex map.
// If the map reaches capacity, clear it to avoid memory consumption issues.
// This is safe, as the map contains references to redsync mutexes, which are stored in Redis.
// Clearing the map only removes their local reference.
// The redsync mutexes themselves can still be acquired and used elsewhere.
func (store *DistributedRedisStoreWithExpiry) newMutex(name string) *redsync.Mutex {
	if atomic.LoadUint32(&store.mutexSize) >= capacity {
		store.mutex.Clear()
		log.Info("gobreaker: cleared distributed redis store as it has reached capacity")
		atomic.StoreUint32(&store.mutexSize, 0)
	}

	mutex := store.rs.NewMutex(name, redsync.WithExpiry(mutexTimeout))
	store.mutex.Store(name, mutex)
	atomic.AddUint32(&store.mutexSize, 1)

	return mutex
}

func sharedStateKey(userKey string) string {
	return "gobreaker:state:" + userKey
}

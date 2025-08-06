/*
* This is a custom implementation of gobreaker.RedisStore. This implementation accepts a Redis client instead of an address.
* It also sets the expiry of keys in the store to keyExpiry instead of having no expiry.
 */

package circuitbreaker

import (
	"context"
	"fmt"
	"time"

	redsync "github.com/go-redsync/redsync/v4"
	goredis "github.com/go-redsync/redsync/v4/redis/goredis/v9"
	redis "github.com/redis/go-redis/v9"
)

const (
	mutexTimeout = 5 * time.Second
	keyExpiry    = 5 * time.Minute
)

// RedisStore is a custom implementation of gobreaker.RedisStore.
type RedisStore struct {
	ctx    context.Context
	client *redis.Client
	rs     *redsync.Redsync
	mutex  map[string]*redsync.Mutex
}

// NewRedisStore creates a RedisStore given a redis client. This implementation deviates from the gobreaker.RedisStore implementation
// by accepting a client instead of an address.
func NewRedisStore(client *redis.Client) *RedisStore {
	return &RedisStore{
		ctx:    context.TODO(), // Usage of TODO indicates that a background context would ideally be passed in from the main function lint:allow context.TODO
		client: client,
		rs:     redsync.New(goredis.NewPool(client)),
		mutex:  map[string]*redsync.Mutex{},
	}
}

// Lock acquires a distributed lock using the provided name.
func (store *RedisStore) Lock(name string) error {
	mutex, ok := store.mutex[name]
	if ok {
		return mutex.Lock()
	}

	mutex = store.rs.NewMutex(name, redsync.WithExpiry(mutexTimeout))
	store.mutex[name] = mutex
	return mutex.Lock()
}

// Unlock releases the distributed lock using the provided name. This adds additional error handling to the gobreaker.RedisStore
// implementation.
func (store *RedisStore) Unlock(name string) error {
	mutex, ok := store.mutex[name]
	if !ok {
		return fmt.Errorf("unlock failed: mutex %q not found", name)
	}

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
func (store *RedisStore) GetData(name string) ([]byte, error) {
	return store.client.Get(store.ctx, name).Bytes()
}

// SetData stores the provided data for the given key. This implementation deviates from the gobreaker.RedisStore implementation
// by setting an expiry for the key.
func (store *RedisStore) SetData(name string, data []byte) error {
	return store.client.Set(store.ctx, name, data, keyExpiry).Err()
}

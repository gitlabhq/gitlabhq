package circuitbreaker

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
)

func TestRedisStore_Lock_Unlock(t *testing.T) {
	rdb := InitRdb(t)
	store := NewDistributedRedisStoreWithExpiry(rdb)

	locks := []string{"gobreaker:lock:a", "gobreaker:lock:b", "gobreaker:lock:c"}

	for _, lockName := range locks {
		err := store.Lock(lockName)
		require.NoError(t, err)
	}

	// Verify all mutexes are stored
	assert.Len(t, locks, int(store.mutexSize))
	for _, lockName := range locks {
		mutex, exists := store.mutex.Load(lockName)
		assert.True(t, exists)
		assert.NotNil(t, mutex)
	}

	for _, lockName := range locks {
		err := store.Unlock(lockName)
		assert.NoError(t, err)
	}
}

func TestRedisStore_Unlock_NonExistentLock(t *testing.T) {
	rdb := InitRdb(t)
	store := NewDistributedRedisStoreWithExpiry(rdb)

	nonExistentLock := "gobreaker:lock:nonexistent"

	// Try to unlock a lock that was never acquired
	err := store.Unlock(nonExistentLock)
	require.Error(t, err)
	assert.Equal(t, "unlock failed: mutex \"gobreaker:lock:nonexistent\" not found", err.Error())
}

func TestRedisStore_ConcurrentWrites(t *testing.T) {
	rdb := InitRdb(t)

	const numGoroutines = 3
	const numWritesPerGoroutine = 2

	done := make(chan bool, numGoroutines)
	errors := make(chan error, numGoroutines*numWritesPerGoroutine)

	// Launch multiple goroutines, each with its own RedisStore instance sharing the same rdb
	for i := 0; i < numGoroutines; i++ {
		go func(goroutineID int) {
			defer func() { done <- true }()

			store := NewDistributedRedisStoreWithExpiry(rdb)

			for j := 0; j < numWritesPerGoroutine; j++ {
				key := fmt.Sprintf("gobreaker:concurrent:goroutine_%d:write_%d", goroutineID, j)
				data := []byte(fmt.Sprintf("data_from_goroutine_%d_write_%d", goroutineID, j))

				if err := store.SetData(key, data); err != nil {
					errors <- err
				}
			}
		}(i)
	}

	// Wait for goroutines to complete
	for i := 0; i < numGoroutines; i++ {
		<-done
	}
	close(errors)

	var writeErrors []error
	for err := range errors {
		writeErrors = append(writeErrors, err)
	}
	assert.Empty(t, writeErrors, "Expected no errors during concurrent writes, but got: %v", writeErrors)

	// Verify that all data was written correctly
	verificationStore := NewDistributedRedisStoreWithExpiry(rdb)
	for i := 0; i < numGoroutines; i++ {
		for j := 0; j < numWritesPerGoroutine; j++ {
			key := fmt.Sprintf("gobreaker:concurrent:goroutine_%d:write_%d", i, j)
			expectedData := []byte(fmt.Sprintf("data_from_goroutine_%d_write_%d", i, j))

			actualData, err := verificationStore.GetData(key)
			require.NoError(t, err, "Failed to retrieve data for key %s", key)
			assert.Equal(t, expectedData, actualData, "Data mismatch for key %s", key)
		}
	}
}

func TestRedisStore_Lock_ClearsMutex(t *testing.T) {
	rdb := InitRdb(t)
	store := NewDistributedRedisStoreWithExpiry(rdb)

	store.mutexSize = capacity - 1

	store.Lock("user-1")
	assert.Equal(t, uint32(capacity), store.mutexSize)

	store.Lock("user-2")
	assert.Equal(t, uint32(1), store.mutexSize)

	_, user1Present := store.mutex.Load("user-1")
	_, user2Present := store.mutex.Load("user-2")
	assert.False(t, user1Present)
	assert.True(t, user2Present)
}

func TestSharedStateKey(t *testing.T) {
	rdb := InitRdb(t)

	testUserKey := "test-user-123"

	mockRT := &mockRoundTripper{
		response: &http.Response{
			StatusCode: http.StatusTooManyRequests,
			Body:       io.NopCloser(bytes.NewBufferString("rate limited")),
			Header:     http.Header{enableCircuitBreakerHeader: []string{"true"}},
		},
	}

	rt := NewRoundTripper(mockRT, &config.DefaultCircuitBreakerConfig, rdb)

	reqBody, err := json.Marshal(map[string]string{"key_id": testUserKey})
	require.NoError(t, err)
	req, err := http.NewRequest("POST", "http://example.com", bytes.NewBuffer(reqBody))
	require.NoError(t, err)

	resp, err := rt.RoundTrip(req)
	require.NoError(t, err)
	resp.Body.Close()

	keys, err := rdb.Keys(context.Background(), "*"+testUserKey+"*").Result()
	require.NoError(t, err)
	require.Len(t, keys, 1)

	actualGobreakerKey := keys[0]
	ourKey := sharedStateKey(testUserKey)

	assert.Equal(t, actualGobreakerKey, ourKey,
		"Our shared state key should be identical to gobreaker's internal implementation")
}

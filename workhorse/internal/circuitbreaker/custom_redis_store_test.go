package circuitbreaker

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestRedisStore_Lock_Unlock(t *testing.T) {
	rdb := InitRdb(t)
	store := NewRedisStore(rdb)

	locks := []string{"gobreaker:lock:a", "gobreaker:lock:b", "gobreaker:lock:c"}

	for _, lockName := range locks {
		err := store.Lock(lockName)
		require.NoError(t, err)
	}

	// Verify all mutexes are stored
	assert.Len(t, store.mutex, len(locks))
	for _, lockName := range locks {
		mutex, exists := store.mutex[lockName]
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
	store := NewRedisStore(rdb)

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

			store := NewRedisStore(rdb)

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
	verificationStore := NewRedisStore(rdb)
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

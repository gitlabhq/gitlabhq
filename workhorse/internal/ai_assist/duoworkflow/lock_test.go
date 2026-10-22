package duoworkflow

import (
	"context"
	"fmt"
	"testing"
	"time"

	redsync "github.com/go-redsync/redsync/v4"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	redis "github.com/redis/go-redis/v9"
)

func TestWorkflowLockManager_AcquireAndRelease(t *testing.T) {
	rdb := initRdb(t)
	manager := newWorkflowLockManager(rdb)
	require.NotNil(t, manager)

	ctx := context.Background()
	workflowID := "test-workflow-123"

	mutex, err := manager.acquireLock(ctx, workflowID, "software_development")
	require.NoError(t, err)
	require.NotNil(t, mutex)

	manager.releaseLock(ctx, mutex, workflowID)
}

func TestWorkflowLockManager_ConcurrentLockAttempts(t *testing.T) {
	rdb := initRdb(t)
	manager := newWorkflowLockManager(rdb)
	require.NotNil(t, manager)

	ctx := context.Background()
	workflowID := "test-workflow-concurrent"

	// First instance acquires the lock
	mutex1, err := manager.acquireLock(ctx, workflowID, "software_development")
	require.NoError(t, err)
	require.NotNil(t, mutex1)

	// Second instance should fail to acquire the same lock
	mutex2, err := manager.acquireLock(ctx, workflowID, "software_development")
	require.Error(t, err)
	require.Nil(t, mutex2)
	assert.Contains(t, err.Error(), "failed to acquire workflow lock")

	// Release the first lock
	manager.releaseLock(ctx, mutex1, workflowID)

	// Now the second instance should be able to acquire the lock
	mutex3, err := manager.acquireLock(ctx, workflowID, "software_development")
	require.NoError(t, err)
	require.NotNil(t, mutex3)

	manager.releaseLock(ctx, mutex3, workflowID)
}

func TestWorkflowLockManager_MisconfiguredRedis(t *testing.T) {
	manager := newWorkflowLockManager(unreachableRedis(t))
	require.NotNil(t, manager)

	ctx := context.Background()
	workflowID := "test-workflow-concurrent"

	mutex, err := manager.acquireLock(ctx, workflowID, "software_development")
	require.ErrorIs(t, err, errLockIsUnavailable)
	require.Nil(t, mutex)

	manager.releaseLock(ctx, mutex, workflowID)
}

func TestWorkflowLease_acquire(t *testing.T) {
	ctx := context.Background()

	t.Run("does nothing when locking is disabled", func(t *testing.T) {
		lease := newWorkflowLease(nil)

		require.NoError(t, lease.acquire(ctx, "", ""))
		mutex, _ := lease.held()
		require.Nil(t, mutex)
	})

	t.Run("requires a workflow ID", func(t *testing.T) {
		lease := newWorkflowLease(newWorkflowLockManager(initRdb(t)))

		require.ErrorIs(t, lease.acquire(ctx, "", ""), errNoWorkflowID)
	})

	t.Run("fails when another run holds the lock", func(t *testing.T) {
		manager := newWorkflowLockManager(initRdb(t))
		first := newWorkflowLease(manager)
		require.NoError(t, first.acquire(ctx, "lease-taken-test", ""))
		defer first.release(ctx)

		require.ErrorIs(t, newWorkflowLease(manager).acquire(ctx, "lease-taken-test", ""), errFailedToAcquireLock)
	})

	t.Run("proceeds without a lock when Redis is unavailable", func(t *testing.T) {
		lease := newWorkflowLease(newWorkflowLockManager(unreachableRedis(t)))

		require.NoError(t, lease.acquire(ctx, "misconfigured-redis-test", ""))
		mutex, workflowID := lease.held()
		require.Nil(t, mutex)
		require.Equal(t, "misconfigured-redis-test", workflowID)
	})
}

func TestWorkflowLease_release(t *testing.T) {
	ctx := context.Background()
	manager := newWorkflowLockManager(initRdb(t))
	lease := newWorkflowLease(manager)

	// Shutdown can release before the start request has acquired the lock.
	lease.release(ctx)

	require.NoError(t, lease.acquire(ctx, "release-test-123", ""))

	// A lock acquired after an earlier release is still released, and only once.
	lease.release(ctx)
	mutex, _ := lease.held()
	require.Nil(t, mutex)
	lease.release(ctx)

	mutex, err := manager.acquireLock(ctx, "release-test-123", "")
	require.NoError(t, err)
	require.NotNil(t, mutex)

	t.Run("still releases when ctx is canceled", func(t *testing.T) {
		canceled, cancel := context.WithCancel(ctx)
		lease := newWorkflowLease(manager)
		require.NoError(t, lease.acquire(ctx, "release-canceled-test", ""))

		cancel()
		lease.release(canceled)

		_, err := manager.acquireLock(ctx, "release-canceled-test", "")
		require.NoError(t, err)
	})
}

// held reports the lock and workflow ID the lease holds.
func (l *workflowLease) held() (*redsync.Mutex, string) {
	l.mu.Lock()
	defer l.mu.Unlock()

	return l.mutex, l.workflowID
}

func TestWorkflowLockManager_metrics(t *testing.T) {
	ctx := context.Background()
	manager := newWorkflowLockManager(initRdb(t))
	// A key per run, so a run that dies holding the lock can't fail the next.
	key := fmt.Sprintf("lock-metrics-test-%d", time.Now().UnixNano())
	acquired := counterVecValue(t, lockAcquireTotal, lockOutcomeAcquired)
	taken := counterVecValue(t, lockAcquireTotal, lockOutcomeTaken)
	transient := counterVecValue(t, lockAcquireTotal, lockOutcomeTransientError)

	mutex, err := manager.acquireLock(ctx, key, "")
	require.NoError(t, err)
	_, err = manager.acquireLock(ctx, key, "")
	require.Error(t, err)
	manager.releaseLock(ctx, mutex, key)

	unavailable := newWorkflowLockManager(unreachableRedis(t))
	_, err = unavailable.acquireLock(ctx, key, "")
	require.ErrorIs(t, err, errLockIsUnavailable)

	require.InDelta(t, acquired+1, counterVecValue(t, lockAcquireTotal, lockOutcomeAcquired), 0)
	require.InDelta(t, taken+1, counterVecValue(t, lockAcquireTotal, lockOutcomeTaken), 0)
	require.InDelta(t, transient+1, counterVecValue(t, lockAcquireTotal, lockOutcomeTransientError), 0)

	t.Run("counts a release that fails", func(t *testing.T) {
		failures := counterValue(t, lockReleaseFailuresTotal)
		mutex, err := manager.acquireLock(ctx, key+"-release", "")
		require.NoError(t, err)
		defer manager.releaseLock(ctx, mutex, key+"-release")

		canceled, cancel := context.WithCancel(ctx)
		cancel()
		manager.releaseLock(canceled, mutex, key+"-release")

		require.InDelta(t, failures+1, counterValue(t, lockReleaseFailuresTotal), 0)
	})
}

// unreachableRedis returns a client for a Redis that refuses every connection.
// Port 1 always refuses, while the default localhost:6379 is a live service on
// the kubernetes executor. Retries are disabled so a refused call fails at once.
func unreachableRedis(t *testing.T) *redis.Client {
	t.Helper()

	rdb := redis.NewClient(&redis.Options{Addr: "localhost:1", MaxRetries: -1, DialerRetries: 1})
	t.Cleanup(func() { _ = rdb.Close() })

	return rdb
}

package duoworkflow

import (
	"context"
	"testing"

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
	// Port 1 always refuses. The default localhost:6379 is a live service on the kubernetes executor.
	rdb := redis.NewClient(&redis.Options{Addr: "localhost:1"})
	manager := newWorkflowLockManager(rdb)
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

		require.ErrorIs(t, newWorkflowLease(manager).acquire(ctx, "lease-taken-test", ""), errFailedToAcquireLockError)
	})

	t.Run("proceeds without a lock when Redis is unavailable", func(t *testing.T) {
		// Port 1 always refuses. The default localhost:6379 is a live service on the kubernetes executor.
		lease := newWorkflowLease(newWorkflowLockManager(redis.NewClient(&redis.Options{Addr: "localhost:1"})))

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

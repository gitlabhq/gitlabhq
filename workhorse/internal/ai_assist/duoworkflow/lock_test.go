package duoworkflow

import (
	"context"
	"testing"

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

	manager.releaseLock(ctx, mutex, workflowID, "software_development")
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
	manager.releaseLock(ctx, mutex1, workflowID, "software_development")

	// Now the second instance should be able to acquire the lock
	mutex3, err := manager.acquireLock(ctx, workflowID, "software_development")
	require.NoError(t, err)
	require.NotNil(t, mutex3)

	manager.releaseLock(ctx, mutex3, workflowID, "software_development")
}

func TestWorkflowLockManager_MisconfiguredRedis(t *testing.T) {
	rdb := redis.NewClient(&redis.Options{})
	manager := newWorkflowLockManager(rdb)
	require.NotNil(t, manager)

	ctx := context.Background()
	workflowID := "test-workflow-concurrent"

	mutex, err := manager.acquireLock(ctx, workflowID, "software_development")
	require.ErrorIs(t, err, errLockIsUnavailable)
	require.Nil(t, mutex)

	manager.releaseLock(ctx, mutex, workflowID, "software_development")
}

package duoworkflow

import (
	"context"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

func TestWorkflowLockManager_AcquireAndRelease(t *testing.T) {
	rdb := initRdb(t)
	manager := newWorkflowLockManager(rdb)
	require.NotNil(t, manager)

	ctx := context.Background()
	workflowID := "test-workflow-123"

	mutex, err := manager.acquireLock(ctx, workflowID)
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
	mutex1, err := manager.acquireLock(ctx, workflowID)
	require.NoError(t, err)
	require.NotNil(t, mutex1)

	// Second instance should fail to acquire the same lock
	mutex2, err := manager.acquireLock(ctx, workflowID)
	require.Error(t, err)
	require.Nil(t, mutex2)
	assert.Contains(t, err.Error(), "failed to acquire workflow lock")

	// Release the first lock
	manager.releaseLock(ctx, mutex1, workflowID)

	// Now the second instance should be able to acquire the lock
	mutex3, err := manager.acquireLock(ctx, workflowID)
	require.NoError(t, err)
	require.NotNil(t, mutex3)

	manager.releaseLock(ctx, mutex3, workflowID)
}

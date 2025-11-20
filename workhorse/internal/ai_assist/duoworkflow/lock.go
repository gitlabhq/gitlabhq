package duoworkflow

import (
	"context"
	"fmt"
	"time"

	redsync "github.com/go-redsync/redsync/v4"
	goredis "github.com/go-redsync/redsync/v4/redis/goredis/v9"
	redis "github.com/redis/go-redis/v9"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

const (
	// We assume 2 hours is a long enough timeout as auth tokens expire after 2
	// hours. In normal cases the lock should be released automatically when
	// the flow ends but in case of sudden shutdown of workhorse this means the
	// flow might be locked for 2 hours.
	workflowLockTimeout = 2 * time.Hour
	workflowLockPrefix  = "workhorse:duoworkflow:lock:"
)

type workflowLockManager struct {
	rs  *redsync.Redsync
	rdb *redis.Client
}

func newWorkflowLockManager(rdb *redis.Client) *workflowLockManager {
	if rdb == nil {
		return nil
	}

	return &workflowLockManager{
		rs:  redsync.New(goredis.NewPool(rdb)),
		rdb: rdb,
	}
}

// When a flow is running we need a distributed lock so that it can be resumed
// concurrently from another workhorse instance. We store these distributed
// locks in Redis keyed by the workflow ID.
func (m *workflowLockManager) acquireLock(ctx context.Context, workflowID string) (*redsync.Mutex, error) {
	lockKey := workflowLockPrefix + workflowID
	mutex := m.rs.NewMutex(lockKey, redsync.WithExpiry(workflowLockTimeout))

	if err := mutex.TryLockContext(ctx); err != nil {
		return nil, fmt.Errorf("failed to acquire workflow lock: %w", err)
	}

	log.WithContextFields(ctx, log.Fields{
		"workflow_id": workflowID,
		"lock_key":    lockKey,
	}).Info("Acquired workflow lock")

	return mutex, nil
}

func (m *workflowLockManager) releaseLock(ctx context.Context, mutex *redsync.Mutex, workflowID string) {
	if m == nil || mutex == nil {
		return
	}

	ok, err := mutex.UnlockContext(ctx)
	if err != nil {
		log.WithContextFields(ctx, log.Fields{
			"workflow_id": workflowID,
		}).WithError(err).Error("Failed to release workflow lock")
		return
	}

	if !ok {
		log.WithContextFields(ctx, log.Fields{
			"workflow_id": workflowID,
		}).Info("Failed to release workflow lock without an error")
		return
	}

	log.WithContextFields(ctx, log.Fields{
		"workflow_id": workflowID,
	}).Info("Released workflow lock")
}

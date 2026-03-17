package duoworkflow

import (
	"context"
	"errors"
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

var errLockIsUnavailable = errors.New("acquireLock: lock is inavailable")

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
func (m *workflowLockManager) acquireLock(ctx context.Context, workflowID string, workflowDefinition string) (*redsync.Mutex, error) {
	lockKey := workflowLockPrefix + workflowID
	mutex := m.rs.NewMutex(lockKey, redsync.WithExpiry(workflowLockTimeout))

	logger := log.WithContextFields(ctx, log.Fields{"workflow_id": workflowID, "lock_key": lockKey, "workflow_definition": workflowDefinition})

	if err := mutex.TryLockContext(ctx); err != nil {
		// Only fail the request if the lock is already taken by another process.
		// For other errors (e.g., network issues), we proceed without the lock.
		var errTaken *redsync.ErrTaken
		if errors.As(err, &errTaken) {
			logger.WithError(err).Error("Failed to acquire workflow lock: already taken")
			return nil, fmt.Errorf("failed to acquire workflow lock: %w", err)
		}

		logger.WithError(err).Error("Failed to acquire workflow lock due to transient error, proceeding without lock")

		return nil, errLockIsUnavailable
	}

	logger.Info("Acquired workflow lock")

	return mutex, nil
}

func (m *workflowLockManager) releaseLock(ctx context.Context, mutex *redsync.Mutex, workflowID string, workflowDefinition string) {
	if m == nil || mutex == nil {
		return
	}

	logger := log.WithContextFields(ctx, log.Fields{
		"workflow_id": workflowID, "workflow_definition": workflowDefinition,
	})

	ok, err := mutex.UnlockContext(ctx)
	if err != nil {
		if errors.Is(err, redsync.ErrLockAlreadyExpired) {
			logger.Info("Workflow lock was already expired")
			return
		}

		logger.WithError(err).Error("Failed to release workflow lock")
		return
	}

	if !ok {
		logger.Info("Failed to release workflow lock without an error")
		return
	}

	logger.Info("Released workflow lock")
}

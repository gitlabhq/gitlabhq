package duoworkflow

import (
	"context"
	"errors"
	"sync/atomic"
	"testing"
	"time"

	"github.com/prometheus/client_golang/prometheus/testutil"
	"github.com/stretchr/testify/require"
)

func TestActionPool_runsUpToSizeConcurrently(t *testing.T) {
	pool := newActionPool(context.Background(), 2, make(chan error, 1))
	t.Cleanup(func() { pool.close(time.Second) })

	saturatedBefore := testutil.ToFloat64(actionPoolSaturatedTotal)

	started := make(chan struct{}, 3)
	release := make(chan struct{})
	submit := func() error {
		return pool.submit(actionTypeHTTP, func(context.Context) error {
			started <- struct{}{}
			<-release
			return nil
		})
	}

	require.NoError(t, submit())
	require.NoError(t, submit())
	<-started
	<-started

	third := make(chan error, 1)
	go func() { third <- submit() }()

	select {
	case <-started:
		t.Fatal("a third action must wait for a free worker")
	case <-time.After(50 * time.Millisecond):
	}

	close(release)
	require.NoError(t, <-third)
	<-started

	require.InDelta(t, saturatedBefore+1, testutil.ToFloat64(actionPoolSaturatedTotal), 0)
}

func TestActionPool_reportsTheFirstErrorAndCancels(t *testing.T) {
	errCh := make(chan error, 1)
	pool := newActionPool(context.Background(), 2, errCh)
	t.Cleanup(func() { pool.close(time.Second) })

	sendErr := errors.New("failed to send gRPC message")

	canceled := make(chan error, 1)
	require.NoError(t, pool.submit(actionTypeMCP, func(ctx context.Context) error {
		<-ctx.Done()
		canceled <- context.Cause(ctx)
		return errors.New("a second error")
	}))
	require.NoError(t, pool.submit(actionTypeHTTP, func(context.Context) error {
		return sendErr
	}))

	require.ErrorIs(t, <-errCh, sendErr)
	require.ErrorIs(t, <-canceled, sendErr, "actions in flight are canceled")

	require.True(t, pool.close(time.Second))
	require.Empty(t, errCh, "only the first error is reported")

	ran := false
	err := pool.submit(actionTypeHTTP, func(context.Context) error {
		ran = true
		return nil
	})
	require.ErrorIs(t, err, sendErr)
	require.False(t, ran)
}

func TestActionPool_submitStopsWaitingWhenCanceled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	pool := newActionPool(ctx, 1, make(chan error, 1))

	release := make(chan struct{})
	require.NoError(t, pool.submit(actionTypeHTTP, func(context.Context) error {
		<-release
		return nil
	}))

	submitted := make(chan error, 1)
	go func() {
		submitted <- pool.submit(actionTypeHTTP, func(context.Context) error { return nil })
	}()

	cancel()
	require.ErrorIs(t, <-submitted, context.Canceled)

	close(release)
	require.True(t, pool.close(time.Second))
}

func TestActionPool_close(t *testing.T) {
	t.Run("cancels actions in flight and waits for them", func(t *testing.T) {
		pool := newActionPool(context.Background(), 2, make(chan error, 1))

		var returned atomic.Bool
		require.NoError(t, pool.submit(actionTypeMCP, func(ctx context.Context) error {
			<-ctx.Done()
			time.Sleep(10 * time.Millisecond)
			returned.Store(true)
			return nil
		}))

		require.True(t, pool.close(time.Second))
		require.True(t, returned.Load())
	})

	t.Run("gives up after the timeout", func(t *testing.T) {
		pool := newActionPool(context.Background(), 1, make(chan error, 1))

		release := make(chan struct{})
		t.Cleanup(func() { close(release) })
		require.NoError(t, pool.submit(actionTypeMCP, func(context.Context) error {
			<-release
			return nil
		}))

		require.False(t, pool.close(10*time.Millisecond))
	})

	t.Run("rejects later submissions", func(t *testing.T) {
		pool := newActionPool(context.Background(), 1, make(chan error, 1))
		require.True(t, pool.close(time.Second))

		ran := false
		err := pool.submit(actionTypeHTTP, func(context.Context) error {
			ran = true
			return nil
		})
		require.ErrorIs(t, err, errActionPoolClosed)
		require.False(t, ran)
	})

	t.Run("is a no-op without a pool", func(t *testing.T) {
		var pool *actionPool
		require.True(t, pool.close(time.Second))
	})
}

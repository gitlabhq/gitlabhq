package shutdown

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

type mockCloser struct {
	shutdownFunc func(ctx context.Context) error
	callCount    int
}

func (m *mockCloser) Shutdown(ctx context.Context) error {
	m.callCount++
	if m.shutdownFunc != nil {
		return m.shutdownFunc(ctx)
	}
	return nil
}

func TestShutdownAll_EmptyClosers(t *testing.T) {
	err := ShutdownAll(context.Background())
	require.NoError(t, err)
}

func TestShutdownAll_SingleCloser(t *testing.T) {
	closer := &mockCloser{}

	err := ShutdownAll(context.Background(), closer)
	require.NoError(t, err)
	require.Equal(t, 1, closer.callCount)
}

func TestShutdownAll_MultipleClosers(t *testing.T) {
	closer1 := &mockCloser{}
	closer2 := &mockCloser{}

	err := ShutdownAll(context.Background(), closer1, closer2)
	require.NoError(t, err)
	require.Equal(t, 1, closer1.callCount)
	require.Equal(t, 1, closer2.callCount)
}

func TestShutdownAll_WithErrors(t *testing.T) {
	expectedErr1 := errors.New("shutdown error 1")
	expectedErr2 := errors.New("shutdown error 2")

	closer1 := &mockCloser{
		shutdownFunc: func(_ context.Context) error {
			return expectedErr1
		},
	}
	closer2 := &mockCloser{
		shutdownFunc: func(_ context.Context) error {
			return expectedErr2
		},
	}

	err := ShutdownAll(context.Background(), closer1, closer2)
	require.Error(t, err)
	require.ErrorIs(t, err, expectedErr1)
	require.ErrorIs(t, err, expectedErr2)
}

func TestShutdownAll_ContextTimeout(t *testing.T) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Millisecond)
	defer cancel()

	closer := &mockCloser{
		shutdownFunc: func(ctx context.Context) error {
			<-ctx.Done()
			return ctx.Err()
		},
	}

	err := ShutdownAll(ctx, closer)
	require.Error(t, err)
	require.ErrorIs(t, err, context.DeadlineExceeded)
}

func TestShutdownAll_MixedSuccessAndFailure(t *testing.T) {
	expectedErr := errors.New("shutdown error")

	closer1 := &mockCloser{
		shutdownFunc: func(_ context.Context) error {
			return nil
		},
	}
	closer2 := &mockCloser{
		shutdownFunc: func(_ context.Context) error {
			return expectedErr
		},
	}
	closer3 := &mockCloser{
		shutdownFunc: func(_ context.Context) error {
			return nil
		},
	}

	err := ShutdownAll(context.Background(), closer1, closer2, closer3)
	require.Error(t, err)
	require.ErrorIs(t, err, expectedErr)
}

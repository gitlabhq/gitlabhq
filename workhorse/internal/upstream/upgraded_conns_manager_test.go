package upstream

import (
	"context"
	"testing"
	"time"

	"github.com/stretchr/testify/require"
)

type mockHandler struct {
	shutdownFunc func(ctx context.Context) error
	callCount    int
}

func (m *mockHandler) Shutdown(ctx context.Context) error {
	m.callCount++
	if m.shutdownFunc != nil {
		return m.shutdownFunc(ctx)
	}
	return nil
}

func TestUpgradedConnsManager_Register(t *testing.T) {
	manager := &UpgradedConnsManager{}
	handler := &mockHandler{}

	manager.Register(handler)

	require.Len(t, manager.handlers, 1)
}

func TestUpgradedConnsManager_Shutdown(t *testing.T) {
	manager := &UpgradedConnsManager{}

	handler := &mockHandler{
		shutdownFunc: func(_ context.Context) error {
			return nil
		},
	}
	manager.Register(handler)

	manager.Shutdown(15 * time.Second)
	require.Equal(t, 1, handler.callCount)
}

func TestUpgradedConnsManager_Shutdown_MultipleHandlers(t *testing.T) {
	manager := &UpgradedConnsManager{}

	handler1 := &mockHandler{}
	handler2 := &mockHandler{}

	manager.Register(handler1)
	manager.Register(handler2)

	manager.Shutdown(15 * time.Second)
	require.Equal(t, 1, handler1.callCount)
	require.Equal(t, 1, handler2.callCount)
}

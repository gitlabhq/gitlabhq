package upstream

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
)

type mockHandler struct {
	shutdownFunc func(ctx context.Context) error
}

func (m *mockHandler) Shutdown(ctx context.Context) error {
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

func TestUpgradedConnsManager_Shutdown_NilManager(t *testing.T) {
	var manager *UpgradedConnsManager
	err := manager.Shutdown(context.Background())
	require.NoError(t, err)
}

func TestUpgradedConnsManager_Shutdown_NoHandlers(t *testing.T) {
	manager := &UpgradedConnsManager{}
	err := manager.Shutdown(context.Background())
	require.NoError(t, err)
}

func TestUpgradedConnsManager_Shutdown(t *testing.T) {
	manager := &UpgradedConnsManager{}
	called := false

	handler := &mockHandler{
		shutdownFunc: func(_ context.Context) error {
			called = true
			return nil
		},
	}
	manager.Register(handler)

	err := manager.Shutdown(context.Background())
	require.NoError(t, err)
	require.True(t, called)
}

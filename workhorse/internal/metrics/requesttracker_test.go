package metrics

import (
	"context"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestSetAndGetFlag(t *testing.T) {
	rt := NewRequestTracker()

	// Test setting and getting a flag
	rt.SetFlag("test_key", "test_value")
	val, ok := rt.GetFlag("test_key")

	require.True(t, ok)
	require.Equal(t, "test_value", val)

	// Test getting a non-existent flag
	val, ok = rt.GetFlag("non_existent")

	require.False(t, ok)
	require.Empty(t, val)

	// Test overwriting a flag
	rt.SetFlag("test_key", "new_value")
	val, ok = rt.GetFlag("test_key")

	require.True(t, ok)
	require.Equal(t, "new_value", val)
}

func TestHasFlag(t *testing.T) {
	rt := NewRequestTracker()

	// Set a flag
	rt.SetFlag("test_key", "test_value")

	// Test HasFlag with correct value
	require.True(t, rt.HasFlag("test_key", "test_value"))

	// Test HasFlag with incorrect value
	require.False(t, rt.HasFlag("test_key", "wrong_value"))

	// Test HasFlag with non-existent key
	require.False(t, rt.HasFlag("non_existent", "any_value"))
}

func TestContextOperations(t *testing.T) {
	// Create a base context
	ctx := context.Background()

	// Create a request tracker
	rt := NewRequestTracker()
	rt.SetFlag("test_key", "test_value")

	// Test NewContext
	ctxWithTracker := NewContext(ctx, rt)
	require.NotEqual(t, ctx, ctxWithTracker)

	// Test FromContext - successful retrieval
	retrievedRT, ok := FromContext(ctxWithTracker)
	require.True(t, ok)

	// Verify the retrieved tracker has the expected flag
	val, ok := retrievedRT.GetFlag("test_key")
	require.True(t, ok)
	require.Equal(t, "test_value", val)

	// Test FromContext - no tracker in context
	emptyRT, ok := FromContext(ctx)
	require.False(t, ok)
	require.Nil(t, emptyRT)
}

func TestPredefinedConstants(t *testing.T) {
	// Test using the predefined constant
	rt := NewRequestTracker()
	rt.SetFlag(KeyFetchedExternalURL, "true")

	val, ok := rt.GetFlag(KeyFetchedExternalURL)
	require.True(t, ok)
	require.Equal(t, "true", val)

	require.True(t, rt.HasFlag(KeyFetchedExternalURL, "true"))
}

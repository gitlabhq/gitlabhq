package transport

import (
	"testing"

	"github.com/stretchr/testify/require"
)

func TestNewDefaultTransport(t *testing.T) {
	require.IsType(t, &DefaultTransport{}, NewDefaultTransport())
}

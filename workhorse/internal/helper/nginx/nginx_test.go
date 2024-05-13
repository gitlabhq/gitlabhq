package nginx

import (
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestDisableResponseBuffering(t *testing.T) {
	rw := httptest.NewRecorder()

	DisableResponseBuffering(rw)

	require.Equal(t, "no", rw.Header().Get(ResponseBufferHeader))
}

func TestAllowResponseBuffering(t *testing.T) {
	rw := httptest.NewRecorder()

	rw.Header().Set(ResponseBufferHeader, "no")

	require.Equal(t, "no", rw.Header().Get(ResponseBufferHeader))

	AllowResponseBuffering(rw)

	require.Equal(t, "", rw.Header().Get(ResponseBufferHeader))
}

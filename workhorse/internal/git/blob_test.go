package git

import (
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestSetBlobHeaders(t *testing.T) {
	w := httptest.NewRecorder()
	w.Header().Set("Set-Cookie", "gitlab_cookie=123456")

	setBlobHeaders(w)

	require.Empty(t, w.Header().Get("Set-Cookie"), "remove Set-Cookie")
}

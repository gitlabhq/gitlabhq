package upstream

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestDevelopmentModeEnabled(t *testing.T) {
	developmentMode := true

	r, _ := http.NewRequest("GET", "/something", nil)
	w := httptest.NewRecorder()

	executed := false
	NotFoundUnless(developmentMode, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		executed = true
	})).ServeHTTP(w, r)

	require.True(t, executed, "The handler should get executed")
}

func TestDevelopmentModeDisabled(t *testing.T) {
	developmentMode := false

	r, _ := http.NewRequest("GET", "/something", nil)
	w := httptest.NewRecorder()

	executed := false
	NotFoundUnless(developmentMode, http.HandlerFunc(func(_ http.ResponseWriter, _ *http.Request) {
		executed = true
	})).ServeHTTP(w, r)

	require.False(t, executed, "The handler should not get executed")

	require.Equal(t, 404, w.Code)
}

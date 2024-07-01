package rejectmethods

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestNewMiddleware(t *testing.T) {
	handler := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		io.WriteString(w, "OK\n")
	})

	middleware := NewMiddleware(handler)

	acceptedMethods := []string{"GET", "HEAD", "POST", "PUT", "PATCH", "DELETE", "CONNECT", "OPTIONS", "TRACE"}
	for _, method := range acceptedMethods {
		t.Run(method, func(t *testing.T) {
			tmpRequest, _ := http.NewRequest(method, "/", nil)
			recorder := httptest.NewRecorder()

			middleware.ServeHTTP(recorder, tmpRequest)

			result := recorder.Result()
			defer func() { _ = result.Body.Close() }()

			require.Equal(t, http.StatusOK, result.StatusCode)
		})
	}

	t.Run("UNKNOWN", func(t *testing.T) {
		tmpRequest, _ := http.NewRequest("UNKNOWN", "/", nil)
		recorder := httptest.NewRecorder()
		defer func() { _ = recorder.Result().Body.Close() }()

		middleware.ServeHTTP(recorder, tmpRequest)

		result := recorder.Result()
		defer func() { _ = result.Body.Close() }()

		require.Equal(t, http.StatusMethodNotAllowed, result.StatusCode)
	})
}

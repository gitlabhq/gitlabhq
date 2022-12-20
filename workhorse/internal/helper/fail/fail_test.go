package fail

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestRequestWorksWithNils(t *testing.T) {
	body := bytes.NewBuffer(nil)
	w := httptest.NewRecorder()
	w.Body = body

	Request(w, nil, nil)

	require.Equal(t, http.StatusInternalServerError, w.Code)
	require.Equal(t, "Internal Server Error\n", body.String())
}

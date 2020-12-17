package headers

import (
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestIsDetectContentTypeHeaderPresent(t *testing.T) {
	rw := httptest.NewRecorder()

	rw.Header().Del(GitlabWorkhorseDetectContentTypeHeader)
	require.Equal(t, false, IsDetectContentTypeHeaderPresent(rw))

	rw.Header().Set(GitlabWorkhorseDetectContentTypeHeader, "true")
	require.Equal(t, true, IsDetectContentTypeHeaderPresent(rw))

	rw.Header().Set(GitlabWorkhorseDetectContentTypeHeader, "false")
	require.Equal(t, false, IsDetectContentTypeHeaderPresent(rw))

	rw.Header().Set(GitlabWorkhorseDetectContentTypeHeader, "foobar")
	require.Equal(t, false, IsDetectContentTypeHeaderPresent(rw))
}

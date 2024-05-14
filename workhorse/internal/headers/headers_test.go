package headers

import (
	"net/http/httptest"
	"testing"

	"github.com/stretchr/testify/require"
)

func TestIsDetectContentTypeHeaderPresent(t *testing.T) {
	rw := httptest.NewRecorder()

	rw.Header().Del(GitlabWorkhorseDetectContentTypeHeader)
	require.False(t, IsDetectContentTypeHeaderPresent(rw))

	rw.Header().Set(GitlabWorkhorseDetectContentTypeHeader, "true")
	require.True(t, IsDetectContentTypeHeaderPresent(rw))

	rw.Header().Set(GitlabWorkhorseDetectContentTypeHeader, "false")
	require.False(t, IsDetectContentTypeHeaderPresent(rw))

	rw.Header().Set(GitlabWorkhorseDetectContentTypeHeader, "foobar")
	require.False(t, IsDetectContentTypeHeaderPresent(rw))
}

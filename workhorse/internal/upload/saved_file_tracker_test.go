package upload

import (
	"context"

	"github.com/golang-jwt/jwt/v5"

	"net/http"
	"testing"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
)

func TestSavedFileTracking(t *testing.T) {
	testhelper.ConfigureSecret()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	r, err := http.NewRequestWithContext(ctx, "PUT", "/url/path", nil)
	require.NoError(t, err)

	tracker := SavedFileTracker{Request: r}
	require.Equal(t, "accelerate", tracker.Name())

	file := &destination.FileHandler{}
	tracker.ProcessFile(ctx, "test", file, nil, config.NewDefaultConfig())
	require.Equal(t, 1, tracker.Count())

	tracker.Finalize(ctx)
	token, err := jwt.ParseWithClaims(r.Header.Get(RewrittenFieldsHeader), &MultipartClaims{}, testhelper.ParseJWT)
	require.NoError(t, err)

	rewrittenFields := token.Claims.(*MultipartClaims).RewrittenFields
	require.Len(t, rewrittenFields, 1)

	require.Contains(t, rewrittenFields, "test")
}

func TestDuplicatedFileProcessing(t *testing.T) {
	tracker := SavedFileTracker{}
	file := &destination.FileHandler{}

	require.NoError(t, tracker.ProcessFile(context.Background(), "file", file, nil, config.NewDefaultConfig()))

	err := tracker.ProcessFile(context.Background(), "file", file, nil, config.NewDefaultConfig())
	require.Error(t, err)
	require.Equal(t, "the file field has already been processed", err.Error())
}

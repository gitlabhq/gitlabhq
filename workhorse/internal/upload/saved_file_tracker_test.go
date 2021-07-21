package upload

import (
	"context"

	"github.com/dgrijalva/jwt-go"

	"net/http"
	"testing"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/filestore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func TestSavedFileTracking(t *testing.T) {
	testhelper.ConfigureSecret()

	r, err := http.NewRequest("PUT", "/url/path", nil)
	require.NoError(t, err)

	tracker := SavedFileTracker{Request: r}
	require.Equal(t, "accelerate", tracker.Name())

	file := &filestore.FileHandler{}
	ctx := context.Background()
	tracker.ProcessFile(ctx, "test", file, nil)
	require.Equal(t, 1, tracker.Count())

	tracker.Finalize(ctx)
	token, err := jwt.ParseWithClaims(r.Header.Get(RewrittenFieldsHeader), &MultipartClaims{}, testhelper.ParseJWT)
	require.NoError(t, err)

	rewrittenFields := token.Claims.(*MultipartClaims).RewrittenFields
	require.Equal(t, 1, len(rewrittenFields))

	require.Contains(t, rewrittenFields, "test")
}

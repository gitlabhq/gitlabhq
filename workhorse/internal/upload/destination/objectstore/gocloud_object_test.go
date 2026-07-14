package objectstore

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/sirupsen/logrus"
	logrustest "github.com/sirupsen/logrus/hooks/test"
	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/labkit/v2/fields"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/objectstore/test"
)

func TestGoCloudObjectUpload(t *testing.T) {
	oldLevel := logrus.StandardLogger().Level
	logrus.StandardLogger().SetLevel(logrus.DebugLevel)
	defer logrus.StandardLogger().SetLevel(oldLevel)

	hook := logrustest.NewLocal(logrus.StandardLogger())
	defer hook.Reset()

	mux, _ := test.SetupGoCloudFileBucket(t, "azuretest")

	ctx, cancel := context.WithCancel(context.Background())
	deadline := time.Now().Add(testTimeout)

	objectName := "test.png"
	testURL := "azuretest://azure.example.com/test-container"
	p := &GoCloudObjectParams{Ctx: ctx, Mux: mux, BucketURL: testURL, ObjectName: objectName}
	object, err := NewGoCloudObject(p)
	require.NotNil(t, object)
	require.NoError(t, err)

	// copy data
	n, err := object.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
	require.NoError(t, err)
	require.Equal(t, test.ObjectSize, n, "Uploaded file mismatch")

	bucket, err := mux.OpenBucket(ctx, testURL)
	require.NoError(t, err)

	// Verify the data was copied correctly.
	received, err := bucket.ReadAll(ctx, objectName)
	require.NoError(t, err)
	require.Equal(t, []byte(test.ObjectContent), received)

	attr, err := bucket.Attributes(ctx, objectName)
	require.NoError(t, err)
	require.Empty(t, attr.ContentType)

	for _, phase := range []string{"new_writer", "copy", "close"} {
		var found bool
		for _, entry := range hook.AllEntries() {
			if entry.Level != logrus.DebugLevel {
				continue
			}
			if entry.Data["phase"] != phase {
				continue
			}
			found = true
			durationS, ok := entry.Data[fields.DurationS].(float64)
			require.True(t, ok, "duration_s should be a float64 for phase %q", phase)
			require.GreaterOrEqual(t, durationS, float64(0))
		}
		require.True(t, found, "expected a Debug log entry for phase %q", phase)
	}

	cancel()

	require.Eventually(t, func() bool {
		exists, err := bucket.Exists(ctx, objectName)
		require.NoError(t, err)

		return !exists
	}, 5*time.Second, time.Millisecond, "file %s is still present", objectName)
}

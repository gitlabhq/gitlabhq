package objectstore

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/sirupsen/logrus"
	logrustest "github.com/sirupsen/logrus/hooks/test"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/labkit/v2/fields"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/objectstore/test"
)

const uploadSummaryMessage = "object storage upload completed"

func findSummaryEntry(t *testing.T, hook *logrustest.Hook) *logrus.Entry {
	t.Helper()

	for _, entry := range hook.AllEntries() {
		if entry.Message == uploadSummaryMessage {
			return entry
		}
	}

	return nil
}

func TestUploaderConsumeLogsObjectSummary(t *testing.T) {
	tests := []struct {
		name      string
		newServer func(t *testing.T) (*test.ObjectstoreStub, *httptest.Server)
		wantErr   bool
	}{
		{
			name: "success",
			newServer: func(_ *testing.T) (*test.ObjectstoreStub, *httptest.Server) {
				return test.StartObjectStore()
			},
			wantErr: false,
		},
		{
			name: "failure",
			newServer: func(_ *testing.T) (*test.ObjectstoreStub, *httptest.Server) {
				return nil, httptest.NewServer(http.NotFoundHandler())
			},
			wantErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			hook := logrustest.NewLocal(logrus.StandardLogger())
			defer hook.Reset()

			osStub, ts := tt.newServer(t)
			defer ts.Close()

			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			objectURL := ts.URL + test.ObjectPath
			deadline := time.Now().Add(testTimeout)
			object, err := NewObject(objectURL, "", map[string]string{}, test.ObjectSize)
			require.NoError(t, err)

			n, err := object.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
			if tt.wantErr {
				require.Error(t, err)
			} else {
				require.NoError(t, err)
				require.Equal(t, test.ObjectSize, n)
				require.Equal(t, 1, osStub.PutsCnt())
			}

			entry := findSummaryEntry(t, hook)
			require.NotNil(t, entry, "expected an %q log entry", uploadSummaryMessage)
			require.Equal(t, "presigned_put", entry.Data["strategy"])

			if tt.wantErr {
				require.NotEmpty(t, entry.Data[fields.ErrorMessage])
			} else {
				require.NotContains(t, entry.Data, fields.ErrorMessage)
				require.Equal(t, logrus.InfoLevel, entry.Level)
				require.Equal(t, test.ObjectSize, entry.Data["uploaded_bytes"])

				durationS, ok := entry.Data[fields.DurationS].(float64)
				require.True(t, ok, "duration_s should be a float64")
				require.GreaterOrEqual(t, durationS, float64(0))
			}
		})
	}
}

func TestUploaderConsumeLogsSingleSummaryForMultipart(t *testing.T) {
	hook := logrustest.NewLocal(logrus.StandardLogger())
	defer hook.Reset()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := io.ReadAll(r.Body)
		assert.NoError(t, err)
		defer r.Body.Close()

		if r.Method == http.MethodPut {
			w.Header().Set("ETag", strings.ToUpper(test.ObjectMD5))
		}

		if r.Method == http.MethodPost {
			completeBody := `<CompleteMultipartUploadResult>
			                   <Bucket>test-bucket</Bucket>
			                   <ETag>No Longer Checked</ETag>
			                 </CompleteMultipartUploadResult>`
			w.Write([]byte(completeBody))
		}
	}))
	defer ts.Close()

	deadline := time.Now().Add(testTimeout)
	m, err := NewMultipart([]string{ts.URL}, ts.URL, "", "", map[string]string{}, test.ObjectSize)
	require.NoError(t, err)

	_, err = m.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
	require.NoError(t, err)

	var summaryCount int
	for _, entry := range hook.AllEntries() {
		if entry.Message == uploadSummaryMessage {
			summaryCount++
		}
	}
	require.Equal(t, 1, summaryCount, "expected exactly one top-level summary entry")
}

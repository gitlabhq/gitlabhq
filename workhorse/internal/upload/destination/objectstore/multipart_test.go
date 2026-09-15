package objectstore

import (
	"context"
	"crypto/md5"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination/objectstore/test"
)

func TestMultipartUploadWithUpcaseETags(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	var putCnt, postCnt int

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := io.ReadAll(r.Body)
		assert.NoError(t, err)
		defer r.Body.Close()

		// Part upload request
		if r.Method == http.MethodPut {
			putCnt++

			w.Header().Set("ETag", strings.ToUpper(test.ObjectMD5))
		}

		// POST with CompleteMultipartUpload request
		if r.Method == http.MethodPost {
			completeBody := `<CompleteMultipartUploadResult>
			                   <Bucket>test-bucket</Bucket>
			                   <ETag>No Longer Checked</ETag>
			                 </CompleteMultipartUploadResult>`
			postCnt++

			w.Write([]byte(completeBody))
		}
	}))
	defer ts.Close()

	deadline := time.Now().Add(testTimeout)

	m, err := NewMultipart(
		[]string{ts.URL},    // a single presigned part URL
		ts.URL,              // the complete multipart upload URL
		"",                  // no abort
		"",                  // no delete
		map[string]string{}, // no custom headers
		test.ObjectSize)     // parts size equal to the whole content. Only 1 part
	require.NoError(t, err)

	_, err = m.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
	require.NoError(t, err)
	require.Equal(t, 1, putCnt, "1 part expected")
	require.Equal(t, 1, postCnt, "1 complete multipart upload expected")
}

// TestMultipartUploadEmptyParts covers the zero byte part handling: S3 rejects a
// CompleteMultipartUpload that carries no parts, so a zero byte object still
// uploads one empty first part, while a later part that reads no bytes ends the
// loop and is not appended.
func TestMultipartUploadEmptyParts(t *testing.T) {
	tests := []struct {
		name     string
		content  string
		partURLs int
		wantPuts int
	}{
		{name: "zero byte object uploads one empty part", content: "", partURLs: 1, wantPuts: 1},
		{name: "empty later part ends the loop", content: test.ObjectContent, partURLs: 2, wantPuts: 1},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			ctx, cancel := context.WithCancel(context.Background())
			defer cancel()

			var putCnt, postCnt int
			var completeBody string

			ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
				body, err := io.ReadAll(r.Body)
				assert.NoError(t, err)
				defer r.Body.Close()

				// Part upload request
				if r.Method == http.MethodPut {
					putCnt++
					assert.Equal(t, tc.content, string(body), "only the first part is uploaded, with the whole content")

					// The uploader verifies each part against the ETag, so the stub has to
					// answer with the MD5 of what it received, as S3 does.
					w.Header().Set("ETag", fmt.Sprintf("%x", md5.Sum(body)))
				}

				// POST with CompleteMultipartUpload request
				if r.Method == http.MethodPost {
					postCnt++
					completeBody = string(body)

					w.Write([]byte(`<CompleteMultipartUploadResult>
				  <Bucket>test-bucket</Bucket>
				  <ETag>No Longer Checked</ETag>
				</CompleteMultipartUploadResult>`))
				}
			}))
			defer ts.Close()

			deadline := time.Now().Add(testTimeout)

			partURLs := make([]string, tc.partURLs)
			for i := range partURLs {
				partURLs[i] = ts.URL
			}

			m, err := NewMultipart(
				partURLs,            // presigned part URLs
				ts.URL,              // the complete multipart upload URL
				"",                  // no abort
				"",                  // no delete
				map[string]string{}, // no custom headers
				test.ObjectSize)     // the whole content fits in the first part
			require.NoError(t, err)

			_, err = m.Consume(ctx, strings.NewReader(tc.content), deadline)
			require.NoError(t, err)
			require.Equal(t, tc.wantPuts, putCnt)
			require.Equal(t, 1, postCnt, "1 complete multipart upload expected")
			require.Equal(t, tc.wantPuts, strings.Count(completeBody, "<Part>"), "CompleteMultipartUpload carries exactly the uploaded parts")
		})
	}
}

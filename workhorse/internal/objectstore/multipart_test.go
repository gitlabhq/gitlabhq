package objectstore_test

import (
	"context"
	"io/ioutil"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/objectstore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/objectstore/test"
)

func TestMultipartUploadWithUpcaseETags(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	var putCnt, postCnt int

	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := ioutil.ReadAll(r.Body)
		require.NoError(t, err)
		defer r.Body.Close()

		// Part upload request
		if r.Method == "PUT" {
			putCnt++

			w.Header().Set("ETag", strings.ToUpper(test.ObjectMD5))
		}

		// POST with CompleteMultipartUpload request
		if r.Method == "POST" {
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

	m, err := objectstore.NewMultipart(
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

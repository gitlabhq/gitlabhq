package objectstore_test

import (
	"context"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/objectstore"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/objectstore/test"
)

const testTimeout = 10 * time.Second

type osFactory func() (*test.ObjectstoreStub, *httptest.Server)

func testObjectUploadNoErrors(t *testing.T, startObjectStore osFactory, useDeleteURL bool, contentType string) {
	osStub, ts := startObjectStore()
	defer ts.Close()

	objectURL := ts.URL + test.ObjectPath
	var deleteURL string
	if useDeleteURL {
		deleteURL = objectURL
	}

	putHeaders := map[string]string{"Content-Type": contentType}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	deadline := time.Now().Add(testTimeout)
	object, err := objectstore.NewObject(objectURL, deleteURL, putHeaders, test.ObjectSize)
	require.NoError(t, err)

	// copy data
	n, err := object.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)
	require.NoError(t, err)
	require.Equal(t, test.ObjectSize, n, "Uploaded file mismatch")

	require.Equal(t, contentType, osStub.GetHeader(test.ObjectPath, "Content-Type"))

	// Checking MD5 extraction
	require.Equal(t, osStub.GetObjectMD5(test.ObjectPath), object.ETag())

	// Checking cleanup
	cancel()
	require.Equal(t, 1, osStub.PutsCnt(), "Object hasn't been uploaded")

	var expectedDeleteCnt int
	if useDeleteURL {
		expectedDeleteCnt = 1
	}
	// Poll because the object removal is async
	for i := 0; i < 100; i++ {
		if osStub.DeletesCnt() == expectedDeleteCnt {
			break
		}
		time.Sleep(10 * time.Millisecond)
	}

	if useDeleteURL {
		require.Equal(t, 1, osStub.DeletesCnt(), "Object hasn't been deleted")
	} else {
		require.Equal(t, 0, osStub.DeletesCnt(), "Object has been deleted")
	}
}

func TestObjectUpload(t *testing.T) {
	t.Run("with delete URL", func(t *testing.T) {
		testObjectUploadNoErrors(t, test.StartObjectStore, true, "application/octet-stream")
	})
	t.Run("without delete URL", func(t *testing.T) {
		testObjectUploadNoErrors(t, test.StartObjectStore, false, "application/octet-stream")
	})
	t.Run("with custom content type", func(t *testing.T) {
		testObjectUploadNoErrors(t, test.StartObjectStore, false, "image/jpeg")
	})
	t.Run("with upcase ETAG", func(t *testing.T) {
		factory := func() (*test.ObjectstoreStub, *httptest.Server) {
			md5s := map[string]string{
				test.ObjectPath: strings.ToUpper(test.ObjectMD5),
			}

			return test.StartObjectStoreWithCustomMD5(md5s)
		}

		testObjectUploadNoErrors(t, factory, false, "application/octet-stream")
	})
}

func TestObjectUpload404(t *testing.T) {
	ts := httptest.NewServer(http.NotFoundHandler())
	defer ts.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	deadline := time.Now().Add(testTimeout)
	objectURL := ts.URL + test.ObjectPath
	object, err := objectstore.NewObject(objectURL, "", map[string]string{}, test.ObjectSize)
	require.NoError(t, err)
	_, err = object.Consume(ctx, strings.NewReader(test.ObjectContent), deadline)

	require.Error(t, err)
	_, isStatusCodeError := err.(objectstore.StatusCodeError)
	require.True(t, isStatusCodeError, "Should fail with StatusCodeError")
	require.Contains(t, err.Error(), "404")
}

type endlessReader struct{}

func (e *endlessReader) Read(p []byte) (n int, err error) {
	for i := 0; i < len(p); i++ {
		p[i] = '*'
	}

	return len(p), nil
}

// TestObjectUploadBrokenConnection purpose is to ensure that errors caused by the upload destination get propagated back correctly.
// This is important for troubleshooting in production.
func TestObjectUploadBrokenConnection(t *testing.T) {
	// This test server closes connection immediately
	ts := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		hj, ok := w.(http.Hijacker)
		if !ok {
			require.FailNow(t, "webserver doesn't support hijacking")
		}
		conn, _, err := hj.Hijack()
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}
		conn.Close()
	}))
	defer ts.Close()

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	deadline := time.Now().Add(testTimeout)
	objectURL := ts.URL + test.ObjectPath
	object, err := objectstore.NewObject(objectURL, "", map[string]string{}, -1)
	require.NoError(t, err)

	_, copyErr := object.Consume(ctx, &endlessReader{}, deadline)
	require.Error(t, copyErr)
	require.NotEqual(t, io.ErrClosedPipe, copyErr, "We are shadowing the real error")
}

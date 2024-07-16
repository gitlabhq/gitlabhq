package staticpages

import (
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

const (
	errorPage   = "ERROR"
	serverError = "Interesting Server Error"
)

func TestIfErrorPageIsPresented(t *testing.T) {
	dir := t.TempDir()

	os.WriteFile(filepath.Join(dir, "404.html"), []byte(errorPage), 0o600)

	w := httptest.NewRecorder()
	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(404)
		upstreamBody := "Not Found"
		n, err := fmt.Fprint(w, upstreamBody)
		assert.NoError(t, err)
		assert.Len(t, upstreamBody, n, "bytes written")
	})
	st := &Static{DocumentRoot: dir}
	st.ErrorPagesUnless(false, ErrorFormatHTML, h).ServeHTTP(w, nil)
	w.Flush()

	require.Equal(t, 404, w.Code)
	testhelper.RequireResponseBody(t, w, errorPage)
	testhelper.RequireResponseHeader(t, w, "Content-Type", "text/html; charset=utf-8")
}

func TestIfErrorPassedIfNoErrorPageIsFound(t *testing.T) {
	dir := t.TempDir()

	w := httptest.NewRecorder()
	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(404)
		fmt.Fprint(w, errorPage)
	})
	st := &Static{DocumentRoot: dir}
	st.ErrorPagesUnless(false, ErrorFormatHTML, h).ServeHTTP(w, nil)
	w.Flush()

	require.Equal(t, 404, w.Code)
	testhelper.RequireResponseBody(t, w, errorPage)
}

func TestIfErrorPageIsIgnoredInDevelopment(t *testing.T) {
	dir := t.TempDir()

	os.WriteFile(filepath.Join(dir, "500.html"), []byte(errorPage), 0o600)

	w := httptest.NewRecorder()
	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(500)
		fmt.Fprint(w, serverError)
	})
	st := &Static{DocumentRoot: dir}
	st.ErrorPagesUnless(true, ErrorFormatHTML, h).ServeHTTP(w, nil)
	w.Flush()
	require.Equal(t, 500, w.Code)
	testhelper.RequireResponseBody(t, w, serverError)
}

func TestIfErrorPageIsIgnoredIfCustomError(t *testing.T) {
	dir := t.TempDir()

	os.WriteFile(filepath.Join(dir, "500.html"), []byte(errorPage), 0o600)

	w := httptest.NewRecorder()
	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Add("X-GitLab-Custom-Error", "1")
		w.WriteHeader(500)
		fmt.Fprint(w, serverError)
	})
	st := &Static{DocumentRoot: dir}
	st.ErrorPagesUnless(false, ErrorFormatHTML, h).ServeHTTP(w, nil)
	w.Flush()
	require.Equal(t, 500, w.Code)
	testhelper.RequireResponseBody(t, w, serverError)
}

func TestErrorPageInterceptedByContentType(t *testing.T) {
	testCases := []struct {
		contentType string
		intercepted bool
	}{
		{contentType: "application/json", intercepted: false},
		{contentType: "text/plain", intercepted: true},
		{contentType: "text/html", intercepted: true},
		{contentType: "", intercepted: true},
	}

	for _, tc := range testCases {
		dir := t.TempDir()

		os.WriteFile(filepath.Join(dir, "500.html"), []byte(errorPage), 0o600)

		w := httptest.NewRecorder()
		h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			w.Header().Add("Content-Type", tc.contentType)
			w.WriteHeader(500)
			fmt.Fprint(w, serverError)
		})
		st := &Static{DocumentRoot: dir}
		st.ErrorPagesUnless(false, ErrorFormatHTML, h).ServeHTTP(w, nil)
		w.Flush()
		require.Equal(t, 500, w.Code)

		if tc.intercepted {
			testhelper.RequireResponseBody(t, w, errorPage)
		} else {
			testhelper.RequireResponseBody(t, w, serverError)
		}
	}
}

func TestIfErrorPageIsPresentedJSON(t *testing.T) {
	errorPage := "{\"error\":\"Not Found\",\"status\":404}\n"

	w := httptest.NewRecorder()
	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(404)
		upstreamBody := "This string is ignored"
		n, err := fmt.Fprint(w, upstreamBody)
		assert.NoError(t, err)
		assert.Len(t, upstreamBody, n, "bytes written")
	})
	st := &Static{}
	st.ErrorPagesUnless(false, ErrorFormatJSON, h).ServeHTTP(w, nil)
	w.Flush()

	require.Equal(t, 404, w.Code)
	testhelper.RequireResponseBody(t, w, errorPage)
	testhelper.RequireResponseHeader(t, w, "Content-Type", "application/json; charset=utf-8")
}

func TestIfErrorPageIsPresentedText(t *testing.T) {
	errorPage := "Not Found\n"

	w := httptest.NewRecorder()
	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(404)
		upstreamBody := "This string is ignored"
		n, err := fmt.Fprint(w, upstreamBody)
		assert.NoError(t, err)
		assert.Len(t, upstreamBody, n, "bytes written")
	})
	st := &Static{}
	st.ErrorPagesUnless(false, ErrorFormatText, h).ServeHTTP(w, nil)
	w.Flush()

	require.Equal(t, 404, w.Code)
	testhelper.RequireResponseBody(t, w, errorPage)
	testhelper.RequireResponseHeader(t, w, "Content-Type", "text/plain; charset=utf-8")
}

func TestErrorPageResponseWriterFlushable(t *testing.T) {
	rw := httptest.NewRecorder()
	eprw := errorPageResponseWriter{rw: rw}
	rc := http.NewResponseController(&eprw) //nolint:bodyclose // false-positive https://github.com/timakin/bodyclose/issues/52

	err := rc.Flush()
	require.NoError(t, err, "the underlying response writer is not flushable")
	require.True(t, rw.Flushed)
}

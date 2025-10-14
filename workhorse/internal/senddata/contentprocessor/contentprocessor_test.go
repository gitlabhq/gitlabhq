package contentprocessor

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/headers"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

const testData = "Hello world!"

func TestFailSetContentTypeAndDisposition(t *testing.T) {
	testCaseBody := testData

	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		_, err := io.WriteString(w, testCaseBody)
		assert.NoError(t, err)
	})

	resp := makeRequest(t, h, testCaseBody, "")
	defer func() { _ = resp.Body.Close() }()

	require.Empty(t, resp.Header.Get(headers.ContentDispositionHeader))
	require.Empty(t, resp.Header.Get(headers.ContentTypeHeader))
}

func TestSuccessSetContentTypeAndDispositionFeatureEnabled(t *testing.T) {
	testCaseBody := testData

	resp := makeRequest(t, nil, testCaseBody, "")
	defer func() { _ = resp.Body.Close() }()

	require.Equal(t, "inline", resp.Header.Get(headers.ContentDispositionHeader))
	require.Equal(t, "text/plain; charset=utf-8", resp.Header.Get(headers.ContentTypeHeader))
}

func TestSetProperContentTypeAndDisposition(t *testing.T) {
	testCases := []struct {
		desc               string
		contentType        string
		contentDisposition string
		body               string
	}{
		{
			desc:               "text type",
			contentType:        "text/plain; charset=utf-8",
			contentDisposition: "inline",
			body:               testData,
		},
		{
			desc:               "HTML type",
			contentType:        "text/plain; charset=utf-8",
			contentDisposition: "inline; filename=blob",
			body:               "<html><body>Hello world!</body></html>",
		},
		{
			desc:               "Javascript within HTML type",
			contentType:        "text/plain; charset=utf-8",
			contentDisposition: "inline; filename=blob",
			body:               "<script>alert(\"foo\")</script>",
		},
		{
			desc:               "Javascript type",
			contentType:        "text/plain; charset=utf-8",
			contentDisposition: "inline",
			body:               "alert(\"foo\")",
		},
		{
			desc:               "Image type",
			contentType:        "image/png",
			contentDisposition: "inline",
			body:               testhelper.LoadFile(t, "testdata/image.png"),
		},
		{
			desc:               "SVG type",
			contentType:        "image/svg+xml",
			contentDisposition: "attachment",
			body:               testhelper.LoadFile(t, "testdata/image.svg"),
		},
		{
			desc:               "Partial SVG type",
			contentType:        "image/svg+xml",
			contentDisposition: "attachment",
			body:               "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" viewBox=\"0 0 330 82\"><title>SVG logo combined with the W3C logo, set horizontally</title><desc>The logo combines three entities displayed horizontall</desc><metadata>",
		},
		{
			desc:               "Incomplete SVG start tag",
			contentType:        "image/svg+xml",
			contentDisposition: "attachment",
			body:               "<svg xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"",
		},
		{
			desc:               "Application type",
			contentType:        "application/octet-stream",
			contentDisposition: "attachment",
			body:               testhelper.LoadFile(t, "testdata/file.pdf"),
		},
		{
			desc:               "Application type pdf with inline disposition",
			contentType:        "application/pdf",
			contentDisposition: "inline",
			body:               testhelper.LoadFile(t, "testdata/file.pdf"),
		},
		{
			desc:               "Application executable type",
			contentType:        "application/octet-stream",
			contentDisposition: "attachment",
			body:               testhelper.LoadFile(t, "testdata/file.swf"),
		},
		{
			desc:               "Video type",
			contentType:        "video/mp4",
			contentDisposition: "inline",
			body:               testhelper.LoadFile(t, "testdata/video.mp4"),
		},
		{
			desc:               "Audio type",
			contentType:        "application/octet-stream",
			contentDisposition: "attachment",
			body:               testhelper.LoadFile(t, "testdata/audio.mp3"),
		},
		{
			desc:               "JSON type",
			contentType:        "text/plain; charset=utf-8",
			contentDisposition: "inline",
			body:               "{ \"glossary\": { \"title\": \"example glossary\", \"GlossDiv\": { \"title\": \"S\" } } }",
		},
		{
			desc:               "Forged file with png extension but SWF content",
			contentType:        "application/octet-stream",
			contentDisposition: "attachment",
			body:               testhelper.LoadFile(t, "testdata/forgedfile.png"),
		},
		{
			desc:               "BMPR file",
			contentType:        "application/octet-stream",
			contentDisposition: "attachment",
			body:               testhelper.LoadFile(t, "testdata/file.bmpr"),
		},
		{
			desc:               "STL file",
			contentType:        "application/octet-stream",
			contentDisposition: "attachment",
			body:               testhelper.LoadFile(t, "testdata/file.stl"),
		},
		{
			desc:               "RDoc file",
			contentType:        "text/plain; charset=utf-8",
			contentDisposition: "inline",
			body:               testhelper.LoadFile(t, "testdata/file.rdoc"),
		},
		{
			desc:               "IPYNB file",
			contentType:        "text/plain; charset=utf-8",
			contentDisposition: "inline",
			body:               testhelper.LoadFile(t, "testdata/file.ipynb"),
		},
		{
			desc:               "Sketch file",
			contentType:        "application/octet-stream",
			contentDisposition: "attachment",
			body:               testhelper.LoadFile(t, "testdata/file.sketch"),
		},
		{
			desc:               "PDF file with non-ASCII characters in filename",
			contentType:        "application/octet-stream",
			contentDisposition: `attachment; filename="file-ä.pdf"; filename*=UTF-8''file-%c3.pdf`,
			body:               testhelper.LoadFile(t, "testdata/file-ä.pdf"),
		},
		{
			desc:               "Microsoft Word file",
			contentType:        "application/octet-stream",
			contentDisposition: `attachment`,
			body:               testhelper.LoadFile(t, "testdata/file.docx"),
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			resp := makeRequest(t, nil, tc.body, tc.contentDisposition)
			defer func() { _ = resp.Body.Close() }()

			require.Equal(t, tc.contentType, resp.Header.Get(headers.ContentTypeHeader))
			require.Equal(t, tc.contentDisposition, resp.Header.Get(headers.ContentDispositionHeader))
		})
	}
}

func TestFailOverrideContentType(t *testing.T) {
	testCases := []struct {
		desc                 string
		overrideFromUpstream string
		responseContentType  string
		body                 string
	}{
		{
			desc:                 "Force text/html into text/plain",
			responseContentType:  "text/plain; charset=utf-8",
			overrideFromUpstream: "text/html; charset=utf-8",
			body:                 "<html><body>Hello world!</body></html>",
		},
		{
			desc:                 "Force application/javascript into text/plain",
			responseContentType:  "text/plain; charset=utf-8",
			overrideFromUpstream: "application/javascript; charset=utf-8",
			body:                 "alert(1);",
		},
	}

	for _, tc := range testCases {
		t.Run(tc.desc, func(t *testing.T) {
			h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
				// We are pretending to be upstream or an inner layer of the ResponseWriter chain
				w.Header().Set(headers.GitlabWorkhorseDetectContentTypeHeader, "true")
				w.Header().Set(headers.ContentTypeHeader, tc.overrideFromUpstream)
				_, err := io.WriteString(w, tc.body)
				assert.NoError(t, err)
			})

			resp := makeRequest(t, h, tc.body, "")
			defer func() { _ = resp.Body.Close() }()

			require.Equal(t, tc.responseContentType, resp.Header.Get(headers.ContentTypeHeader))
		})
	}
}

func TestSuccessOverrideContentDispositionFromInlineToAttachment(t *testing.T) {
	testCaseBody := testData

	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		// We are pretending to be upstream or an inner layer of the ResponseWriter chain
		w.Header().Set(headers.ContentDispositionHeader, "attachment")
		w.Header().Set(headers.GitlabWorkhorseDetectContentTypeHeader, "true")
		_, err := io.WriteString(w, testCaseBody)
		assert.NoError(t, err)
	})

	resp := makeRequest(t, h, testCaseBody, "")
	defer func() { _ = resp.Body.Close() }()

	require.Equal(t, "attachment", resp.Header.Get(headers.ContentDispositionHeader))
}

func TestInlineContentDispositionForPdfFiles(t *testing.T) {
	testCaseBody := testhelper.LoadFile(t, "testdata/file.pdf")

	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		// We are pretending to be upstream or an inner layer of the ResponseWriter chain
		w.Header().Set(headers.ContentDispositionHeader, "inline")
		w.Header().Set(headers.GitlabWorkhorseDetectContentTypeHeader, "true")
		_, err := io.WriteString(w, testCaseBody)
		assert.NoError(t, err)
	})

	resp := makeRequest(t, h, testCaseBody, "")
	defer func() { _ = resp.Body.Close() }()

	require.Equal(t, "inline", resp.Header.Get(headers.ContentDispositionHeader))
}

func TestFailOverrideContentDispositionFromAttachmentToInline(t *testing.T) {
	testCaseBody := testhelper.LoadFile(t, "testdata/image.svg")

	h := http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		// We are pretending to be upstream or an inner layer of the ResponseWriter chain
		w.Header().Set(headers.ContentDispositionHeader, "inline")
		w.Header().Set(headers.GitlabWorkhorseDetectContentTypeHeader, "true")
		_, err := io.WriteString(w, testCaseBody)
		assert.NoError(t, err)
	})

	resp := makeRequest(t, h, testCaseBody, "")
	defer func() { _ = resp.Body.Close() }()

	require.Equal(t, "attachment", resp.Header.Get(headers.ContentDispositionHeader))
}

func TestHeadersDelete(t *testing.T) {
	for _, code := range []int{200, 400} {
		recorder := httptest.NewRecorder()
		rw := &contentDisposition{rw: recorder}
		for _, name := range headers.ResponseHeaders {
			rw.Header().Set(name, "foobar")
		}

		rw.WriteHeader(code)

		for _, name := range headers.ResponseHeaders {
			if header := recorder.Header().Get(name); header != "" {
				t.Fatalf("HTTP %d response: expected header to be empty, found %q", code, name)
			}
		}
	}
}

func TestWriteHeadersCalledOnce(t *testing.T) {
	recorder := httptest.NewRecorder()
	rw := &contentDisposition{rw: recorder}
	rw.WriteHeader(400)
	require.Equal(t, 400, rw.status)
	require.True(t, rw.sentStatus)

	rw.WriteHeader(200)
	require.Equal(t, 400, rw.status)
}

func makeRequest(t *testing.T, handler http.HandlerFunc, body string, disposition string) *http.Response {
	if handler == nil {
		handler = http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
			// We are pretending to be upstream
			w.Header().Set(headers.GitlabWorkhorseDetectContentTypeHeader, "true")
			w.Header().Set(headers.ContentDispositionHeader, disposition)
			_, err := io.WriteString(w, body)
			assert.NoError(t, err)
		})
	}
	req, _ := http.NewRequest("GET", "/", nil)

	rw := httptest.NewRecorder()
	SetContentHeaders(handler).ServeHTTP(rw, req)

	resp := rw.Result()
	respBody, err := io.ReadAll(resp.Body)
	require.NoError(t, err)

	require.Equal(t, body, string(respBody))

	return resp
}

package dependencyproxy

import (
	"encoding/base64"
	"io"
	"net/http"
	"net/http/httptest"
	"strconv"
	"testing"

	"github.com/stretchr/testify/require"
)

type fakeUploadHandler struct {
	request *http.Request
	body    []byte
	handler func(w http.ResponseWriter, r *http.Request)
}

func (f *fakeUploadHandler) ServeHTTP(w http.ResponseWriter, r *http.Request) {
	f.request = r

	f.body, _ = io.ReadAll(r.Body)

	f.handler(w, r)
}

func TestSuccessfullRequest(t *testing.T) {
	content := []byte("result")
	originResourceServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Length", strconv.Itoa(len(content)))
		w.Write(content)
	}))

	uploadHandler := &fakeUploadHandler{
		handler: func(w http.ResponseWriter, r *http.Request) {
			w.WriteHeader(200)
		},
	}

	injector := NewInjector()
	injector.SetUploadHandler(uploadHandler)

	response := makeRequest(injector, `{"Token": "token", "Url": "`+originResourceServer.URL+`/url"}`)

	require.Equal(t, "/target/upload", uploadHandler.request.URL.Path)
	require.Equal(t, int64(6), uploadHandler.request.ContentLength)

	require.Equal(t, content, uploadHandler.body)

	require.Equal(t, 200, response.Code)
	require.Equal(t, string(content), response.Body.String())
}

func TestIncorrectSendData(t *testing.T) {
	response := makeRequest(NewInjector(), "")

	require.Equal(t, 500, response.Code)
	require.Equal(t, "Internal server error\n", response.Body.String())
}

func TestIncorrectSendDataUrl(t *testing.T) {
	response := makeRequest(NewInjector(), `{"Token": "token", "Url": "url"}`)

	require.Equal(t, 500, response.Code)
	require.Equal(t, "Internal server error\n", response.Body.String())
}

func TestFailedOriginServer(t *testing.T) {
	originResourceServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(404)
		w.Write([]byte("Not found"))
	}))

	uploadHandler := &fakeUploadHandler{
		handler: func(w http.ResponseWriter, r *http.Request) {
			require.FailNow(t, "the error response must not be uploaded")
		},
	}

	injector := NewInjector()
	injector.SetUploadHandler(uploadHandler)

	response := makeRequest(injector, `{"Token": "token", "Url": "`+originResourceServer.URL+`/url"}`)

	require.Equal(t, 404, response.Code)
	require.Equal(t, "Not found", response.Body.String())
}

func makeRequest(injector *Injector, data string) *httptest.ResponseRecorder {
	w := httptest.NewRecorder()
	r := httptest.NewRequest("GET", "/target", nil)

	sendData := base64.StdEncoding.EncodeToString([]byte(data))
	injector.Inject(w, r, sendData)

	return w
}

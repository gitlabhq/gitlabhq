package main

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

type gobAuthServer struct {
	shouldReceiveRequestPath string
	respondWithStatusCode    int
}

type gobUpstreamServer struct {
	shouldReceiveRequestPath string
	shouldBeCalled           bool
	respondWithStatusCode    int
	respondWithBody          string
}

type gobTestCase struct {
	desc   string
	path   string
	method string
	body   string

	shouldRespondWithBody       string
	shouldRespondWithStatusCode int

	authServer gobAuthServer
	upstream   gobUpstreamServer
}

func TestGOBEndpoints(t *testing.T) {
	testCases := [][]gobTestCase{
		genGETTestcases("traces"),
		genGETTestcases("metrics"),
		genGETTestcases("logs"),
		genGETTestcases("analytics"),
		genGETTestcases("services"),

		genPOSTTestcases("traces"),
		genPOSTTestcases("metrics"),
		genPOSTTestcases("logs"),
	}

	for _, signalTestCases := range testCases {
		for _, tc := range signalTestCases {
			t.Run(tc.desc, func(t *testing.T) {
				runTest(t, tc)
			})
		}
	}
}

func genGETTestcases(signal string) []gobTestCase {
	return []gobTestCase{
		{
			desc:   fmt.Sprintf("GET /%s, successful auth, proxies successful upstream", signal),
			method: "GET",
			path:   fmt.Sprintf("/api/v4/projects/1/observability/v1/%s", signal),

			shouldRespondWithBody:       "hello world",
			shouldRespondWithStatusCode: 200,

			authServer: gobAuthServer{
				respondWithStatusCode:    200,
				shouldReceiveRequestPath: fmt.Sprintf("/api/v4/internal/observability/project/1/read/%s", signal),
			},

			upstream: gobUpstreamServer{
				respondWithStatusCode: 200,
				respondWithBody:       "hello world",

				shouldReceiveRequestPath: fmt.Sprintf("/observability/v1/%s", signal),
				shouldBeCalled:           true,
			},
		},
		{
			desc:   fmt.Sprintf("GET /%s with multi-digit projectID, successful auth, proxies successful upstream", signal),
			method: "GET",
			path:   fmt.Sprintf("/api/v4/projects/11111/observability/v1/%s", signal),

			shouldRespondWithBody:       "hello world",
			shouldRespondWithStatusCode: 200,

			authServer: gobAuthServer{
				respondWithStatusCode:    200,
				shouldReceiveRequestPath: fmt.Sprintf("/api/v4/internal/observability/project/11111/read/%s", signal),
			},

			upstream: gobUpstreamServer{
				respondWithStatusCode: 200,
				respondWithBody:       "hello world",

				shouldReceiveRequestPath: fmt.Sprintf("/observability/v1/%s", signal),
				shouldBeCalled:           true,
			},
		},
		{
			desc:   fmt.Sprintf("GET /%s with url-encode projectID, successful auth, proxies successful upstream", signal),
			method: "GET",
			path:   fmt.Sprintf("/api/v4/projects/diaspora%%2Fdiaspora/observability/v1/%s", signal),

			shouldRespondWithBody:       "hello world",
			shouldRespondWithStatusCode: 200,

			authServer: gobAuthServer{
				respondWithStatusCode:    200,
				shouldReceiveRequestPath: fmt.Sprintf("/api/v4/internal/observability/project/diaspora%%2Fdiaspora/read/%s", signal),
			},

			upstream: gobUpstreamServer{
				respondWithStatusCode: 200,
				respondWithBody:       "hello world",

				shouldReceiveRequestPath: fmt.Sprintf("/observability/v1/%s", signal),
				shouldBeCalled:           true,
			},
		},
		{
			desc:   fmt.Sprintf("GET /%s/some/subpath subpath, successful auth, proxies successful upstream", signal),
			method: "GET",
			path:   fmt.Sprintf("/api/v4/projects/1/observability/v1/%s/some/subpath", signal),

			shouldRespondWithBody:       "hello world",
			shouldRespondWithStatusCode: 200,

			authServer: gobAuthServer{
				respondWithStatusCode:    200,
				shouldReceiveRequestPath: fmt.Sprintf("/api/v4/internal/observability/project/1/read/%s", signal),
			},

			upstream: gobUpstreamServer{
				respondWithStatusCode: 200,
				respondWithBody:       "hello world",

				shouldReceiveRequestPath: fmt.Sprintf("/observability/v1/%s/some/subpath", signal),
				shouldBeCalled:           true,
			},
		},
		{
			desc:   fmt.Sprintf("GET /%s, unsuccessful auth, returns auth status code", signal),
			method: "GET",
			path:   fmt.Sprintf("/api/v4/projects/1/observability/v1/%s", signal),

			shouldRespondWithBody:       "",
			shouldRespondWithStatusCode: 401,

			authServer: gobAuthServer{
				respondWithStatusCode:    401,
				shouldReceiveRequestPath: fmt.Sprintf("/api/v4/internal/observability/project/1/read/%s", signal),
			},

			upstream: gobUpstreamServer{
				shouldBeCalled: false,
			},
		},
		{
			desc:   fmt.Sprintf("GET /%s, successful auth, correctly proxies upstream failure", signal),
			method: "GET",
			path:   fmt.Sprintf("/api/v4/projects/1/observability/v1/%s", signal),

			shouldRespondWithBody:       "",
			shouldRespondWithStatusCode: 500,

			authServer: gobAuthServer{
				respondWithStatusCode:    200,
				shouldReceiveRequestPath: fmt.Sprintf("/api/v4/internal/observability/project/1/read/%s", signal),
			},

			upstream: gobUpstreamServer{
				respondWithStatusCode: 500,
				respondWithBody:       "",

				shouldReceiveRequestPath: fmt.Sprintf("/observability/v1/%s", signal),
				shouldBeCalled:           true,
			},
		},
	}
}

func genPOSTTestcases(signal string) []gobTestCase {
	return []gobTestCase{
		{
			desc:   fmt.Sprintf("POST /%s, successful auth, proxies successful upstream", signal),
			method: "POST",
			path:   fmt.Sprintf("/api/v4/projects/1/observability/v1/%s", signal),
			body:   "my posted data",

			shouldRespondWithBody:       "hello world",
			shouldRespondWithStatusCode: 200,

			authServer: gobAuthServer{
				respondWithStatusCode:    200,
				shouldReceiveRequestPath: fmt.Sprintf("/api/v4/internal/observability/project/1/write/%s", signal),
			},

			upstream: gobUpstreamServer{
				respondWithStatusCode: 200,
				respondWithBody:       "hello world",

				shouldReceiveRequestPath: fmt.Sprintf("/observability/v1/%s", signal),
				shouldBeCalled:           true,
			},
		},
		{
			desc:   fmt.Sprintf("POST /%s/some/subpath, successful auth, proxies successful upstream", signal),
			method: "POST",
			path:   fmt.Sprintf("/api/v4/projects/1/observability/v1/%s/some/subpath", signal),
			body:   "my posted data",

			shouldRespondWithBody:       "hello world",
			shouldRespondWithStatusCode: 200,

			authServer: gobAuthServer{
				respondWithStatusCode:    200,
				shouldReceiveRequestPath: fmt.Sprintf("/api/v4/internal/observability/project/1/write/%s", signal),
			},

			upstream: gobUpstreamServer{
				respondWithStatusCode: 200,
				respondWithBody:       "hello world",

				shouldReceiveRequestPath: fmt.Sprintf("/observability/v1/%s/some/subpath", signal),
				shouldBeCalled:           true,
			},
		},
		{
			desc:   fmt.Sprintf("POST /%s, unsuccessful auth, returns auth status code", signal),
			method: "POST",
			path:   fmt.Sprintf("/api/v4/projects/1/observability/v1/%s", signal),
			body:   "my posted data",

			shouldRespondWithBody:       "",
			shouldRespondWithStatusCode: 401,

			authServer: gobAuthServer{
				respondWithStatusCode:    401,
				shouldReceiveRequestPath: fmt.Sprintf("/api/v4/internal/observability/project/1/write/%s", signal),
			},

			upstream: gobUpstreamServer{
				shouldBeCalled: false,
			},
		},
		{
			desc:   fmt.Sprintf("POST /%s, successful auth, correctly proxies upstream failure", signal),
			method: "POST",
			path:   fmt.Sprintf("/api/v4/projects/1/observability/v1/%s", signal),
			body:   "my posted data",

			shouldRespondWithBody:       "",
			shouldRespondWithStatusCode: 500,

			authServer: gobAuthServer{
				respondWithStatusCode:    200,
				shouldReceiveRequestPath: fmt.Sprintf("/api/v4/internal/observability/project/1/write/%s", signal),
			},

			upstream: gobUpstreamServer{
				respondWithStatusCode: 500,
				respondWithBody:       "",

				shouldReceiveRequestPath: fmt.Sprintf("/observability/v1/%s", signal),
				shouldBeCalled:           true,
			},
		},
	}
}

func runTest(t *testing.T, tc gobTestCase) {
	gobSettingsHeaders := map[string]string{
		"foo": "bar",
		"baz": "foobar",
	}

	upstream := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if tc.upstream.shouldBeCalled != true {
			assert.Fail(t, "upstream should not be called")
		}

		assert.Equal(t, tc.upstream.shouldReceiveRequestPath, r.URL.Path, "requested upstream endpoint")
		// Assert that upstream received the headers that were returned in the api.Response
		// from the authServer
		for name, value := range gobSettingsHeaders {
			assert.Equal(t, value, r.Header.Get(name), "received correct header")
		}

		defer r.Body.Close()
		b, err := io.ReadAll(r.Body)
		assert.NoError(t, err)
		assert.Equal(t, tc.body, string(b), "received body upstream")

		w.WriteHeader(tc.upstream.respondWithStatusCode)
		_, err = w.Write([]byte(tc.upstream.respondWithBody))
		assert.NoError(t, err, "write auth response")
	}))
	defer upstream.Close()

	authServer := testhelper.TestServerWithHandler(nil, func(w http.ResponseWriter, r *http.Request) {
		assert.Equal(t, tc.authServer.shouldReceiveRequestPath, r.URL.Path, "requested auth endpoint")
		// Auth request should use the same method as the original Workhorse request
		assert.Equal(t, tc.method, r.Method, "auth request method")

		// return a 204 No Content response if we don't receive the JWT header from Workhorse
		if r.Header.Get(secret.RequestHeader) == "" {
			w.WriteHeader(204)
			return
		}
		w.Header().Set("Content-Type", api.ResponseContentType)

		// Should not receive the body of the original Workhorse request
		defer r.Body.Close()
		b, err := io.ReadAll(r.Body)
		assert.NoError(t, err)
		assert.Empty(t, b)

		data, err := json.Marshal(&api.Response{
			Gob: api.GOBSettings{
				Backend: upstream.URL,
				Headers: gobSettingsHeaders,
			},
		})
		if err != nil {
			w.WriteHeader(503)
			fmt.Fprint(w, err)
			return
		}
		w.WriteHeader(tc.authServer.respondWithStatusCode)
		// Mimic the internal API where response body is only written on success
		if tc.authServer.respondWithStatusCode == 200 {
			w.Write(data)
		}
	})
	defer authServer.Close()

	workhorse := startWorkhorseServer(t, authServer.URL)

	// Do the request
	req, err := http.NewRequest(tc.method, workhorse.URL+tc.path, strings.NewReader(tc.body))
	require.NoError(t, err)

	resp, err := http.DefaultClient.Do(req)
	require.NoError(t, err)
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	require.NoError(t, err)

	assert.Equal(t, tc.shouldRespondWithStatusCode, resp.StatusCode, "response status code")
	assert.Equal(t, tc.shouldRespondWithBody, string(body), "response body")
}

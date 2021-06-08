package main

import (
	"bytes"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io/ioutil"
	"math/rand"
	"net"
	"net/http"
	"net/url"
	"os"
	"os/exec"
	"path"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/golang/protobuf/jsonpb" //lint:ignore SA1019 https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/274
	"github.com/golang/protobuf/proto"  //lint:ignore SA1019 https://gitlab.com/gitlab-org/gitlab-workhorse/-/issues/274
	"github.com/stretchr/testify/require"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"

	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/git"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/testhelper"
)

func TestFailedCloneNoGitaly(t *testing.T) {
	// Prepare clone directory
	require.NoError(t, os.RemoveAll(scratchDir))

	authBody := &api.Response{
		GL_ID:       "user-123",
		GL_USERNAME: "username",
		// This will create a failure to connect to Gitaly
		GitalyServer: gitaly.Server{Address: "unix:/nonexistent"},
	}

	// Prepare test server and backend
	ts := testAuthServer(t, nil, nil, 200, authBody)
	defer ts.Close()
	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	// Do the git clone
	cloneCmd := exec.Command("git", "clone", fmt.Sprintf("%s/%s", ws.URL, testRepo), checkoutDir)
	out, err := cloneCmd.CombinedOutput()
	t.Log(string(out))
	require.Error(t, err, "git clone should have failed")
}

func TestGetInfoRefsProxiedToGitalySuccessfully(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath

	apiResponse := gitOkBody(t)
	apiResponse.GitalyServer.Address = gitalyAddress

	goodMetadata := map[string]string{
		"gitaly-feature-foobar": "true",
		"gitaly-feature-bazqux": "false",
	}
	badMetadata := map[string]string{
		"bad-metadata": "is blocked",
	}

	features := make(map[string]string)
	for k, v := range goodMetadata {
		features[k] = v
	}
	for k, v := range badMetadata {
		features[k] = v
	}
	apiResponse.GitalyServer.Features = features

	testCases := []struct {
		showAllRefs bool
		gitRpc      string
	}{
		{showAllRefs: false, gitRpc: "git-upload-pack"},
		{showAllRefs: true, gitRpc: "git-upload-pack"},
		{showAllRefs: false, gitRpc: "git-receive-pack"},
		{showAllRefs: true, gitRpc: "git-receive-pack"},
	}

	for _, tc := range testCases {
		t.Run(fmt.Sprintf("ShowAllRefs=%v,gitRpc=%v", tc.showAllRefs, tc.gitRpc), func(t *testing.T) {
			apiResponse.ShowAllRefs = tc.showAllRefs

			ts := testAuthServer(t, nil, nil, 200, apiResponse)
			defer ts.Close()

			ws := startWorkhorseServer(ts.URL)
			defer ws.Close()

			gitProtocol := "fake git protocol"
			resource := "/gitlab-org/gitlab-test.git/info/refs?service=" + tc.gitRpc
			resp, body := httpGet(t, ws.URL+resource, map[string]string{"Git-Protocol": gitProtocol})

			require.Equal(t, 200, resp.StatusCode)

			bodySplit := strings.SplitN(body, "\000", 3)
			require.Len(t, bodySplit, 3)

			gitalyRequest := &gitalypb.InfoRefsRequest{}
			require.NoError(t, jsonpb.UnmarshalString(bodySplit[0], gitalyRequest))

			require.Equal(t, gitProtocol, gitalyRequest.GitProtocol)
			if tc.showAllRefs {
				require.Equal(t, []string{git.GitConfigShowAllRefs}, gitalyRequest.GitConfigOptions)
			} else {
				require.Empty(t, gitalyRequest.GitConfigOptions)
			}

			require.Equal(t, tc.gitRpc, bodySplit[1])

			require.Equal(t, string(testhelper.GitalyInfoRefsResponseMock), bodySplit[2], "GET %q: response body", resource)

			md := gitalyServer.LastIncomingMetadata
			for k, v := range goodMetadata {
				actual := md[k]
				require.Len(t, actual, 1, "number of metadata values for %v", k)
				require.Equal(t, v, actual[0], "value for %v", k)
			}

			for k := range badMetadata {
				actual := md[k]
				require.Empty(t, actual, "metadata for bad key %v", k)
			}
		})
	}
}

func TestGetInfoRefsProxiedToGitalyInterruptedStream(t *testing.T) {
	apiResponse := gitOkBody(t)
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath
	apiResponse.GitalyServer.Address = gitalyAddress

	ts := testAuthServer(t, nil, nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/info/refs?service=git-upload-pack"
	resp, err := http.Get(ws.URL + resource)
	require.NoError(t, err)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	waitDone(t, done)
}

func TestGetInfoRefsRouting(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	apiResponse := gitOkBody(t)
	apiResponse.GitalyServer.Address = "unix:" + socketPath
	ts := testAuthServer(t, nil, url.Values{"service": {"git-receive-pack"}}, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	testCases := []struct {
		method string
		path   string
		status int
	}{
		// valid requests
		{"GET", "/toplevel.git/info/refs?service=git-receive-pack", 200},
		{"GET", "/toplevel.wiki.git/info/refs?service=git-receive-pack", 200},
		{"GET", "/toplevel/child/project.git/info/refs?service=git-receive-pack", 200},
		{"GET", "/toplevel/child/project.wiki.git/info/refs?service=git-receive-pack", 200},
		{"GET", "/toplevel/child/project/snippets/123.git/info/refs?service=git-receive-pack", 200},
		{"GET", "/snippets/123.git/info/refs?service=git-receive-pack", 200},
		// failing due to missing service parameter
		{"GET", "/foo/bar.git/info/refs", 403},
		// failing due to invalid service parameter
		{"GET", "/foo/bar.git/info/refs?service=git-zzz-pack", 403},
		// failing due to invalid repository path
		{"GET", "/.git/info/refs?service=git-receive-pack", 204},
		// failing due to invalid request method
		{"POST", "/toplevel.git/info/refs?service=git-receive-pack", 204},
	}

	for _, tc := range testCases {
		t.Run(tc.path, func(t *testing.T) {
			req, err := http.NewRequest(tc.method, ws.URL+tc.path, nil)
			require.NoError(t, err)

			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err)
			defer resp.Body.Close()

			body := string(testhelper.ReadAll(t, resp.Body))

			if tc.status == 200 {
				require.Equal(t, 200, resp.StatusCode)
				require.Contains(t, body, "\x00", "expect response generated by test gitaly server")
			} else {
				require.Equal(t, tc.status, resp.StatusCode)
				require.Empty(t, body, "normal request has empty response body")
			}
		})
	}
}

func waitDone(t *testing.T, done chan struct{}) {
	t.Helper()
	select {
	case <-done:
		return
	case <-time.After(10 * time.Second):
		t.Fatal("time out waiting for gitaly handler to return")
	}
}

func TestPostReceivePackProxiedToGitalySuccessfully(t *testing.T) {
	apiResponse := gitOkBody(t)

	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	apiResponse.GitalyServer.Address = "unix:" + socketPath
	apiResponse.GitConfigOptions = []string{"git-config-hello=world"}
	ts := testAuthServer(t, nil, nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	gitProtocol := "fake Git protocol"
	resource := "/gitlab-org/gitlab-test.git/git-receive-pack"
	resp := httpPost(
		t,
		ws.URL+resource,
		map[string]string{
			"Content-Type": "application/x-git-receive-pack-request",
			"Git-Protocol": gitProtocol,
		},
		bytes.NewReader(testhelper.GitalyReceivePackResponseMock),
	)
	defer resp.Body.Close()
	body := string(testhelper.ReadAll(t, resp.Body))

	split := strings.SplitN(body, "\000", 2)
	require.Len(t, split, 2)

	gitalyRequest := &gitalypb.PostReceivePackRequest{}
	require.NoError(t, jsonpb.UnmarshalString(split[0], gitalyRequest))

	require.Equal(t, apiResponse.Repository.StorageName, gitalyRequest.Repository.StorageName)
	require.Equal(t, apiResponse.Repository.RelativePath, gitalyRequest.Repository.RelativePath)
	require.Equal(t, apiResponse.GL_ID, gitalyRequest.GlId)
	require.Equal(t, apiResponse.GL_USERNAME, gitalyRequest.GlUsername)
	require.Equal(t, apiResponse.GitConfigOptions, gitalyRequest.GitConfigOptions)
	require.Equal(t, gitProtocol, gitalyRequest.GitProtocol)

	require.Equal(t, 200, resp.StatusCode, "POST %q", resource)
	require.Equal(t, string(testhelper.GitalyReceivePackResponseMock), split[1])
	testhelper.RequireResponseHeader(t, resp, "Content-Type", "application/x-git-receive-pack-result")
}

func TestPostReceivePackProxiedToGitalyInterrupted(t *testing.T) {
	apiResponse := gitOkBody(t)

	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	apiResponse.GitalyServer.Address = "unix:" + socketPath
	ts := testAuthServer(t, nil, nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/git-receive-pack"
	resp, err := http.Post(
		ws.URL+resource,
		"application/x-git-receive-pack-request",
		bytes.NewReader(testhelper.GitalyReceivePackResponseMock),
	)
	require.NoError(t, err)
	require.Equal(t, 200, resp.StatusCode, "POST %q", resource)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	waitDone(t, done)
}

func TestPostReceivePackRouting(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	apiResponse := gitOkBody(t)
	apiResponse.GitalyServer.Address = "unix:" + socketPath
	ts := testAuthServer(t, nil, nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	testCases := []struct {
		method      string
		path        string
		contentType string
		match       bool
	}{
		{"POST", "/toplevel.git/git-receive-pack", "application/x-git-receive-pack-request", true},
		{"POST", "/toplevel.wiki.git/git-receive-pack", "application/x-git-receive-pack-request", true},
		{"POST", "/toplevel/child/project.git/git-receive-pack", "application/x-git-receive-pack-request", true},
		{"POST", "/toplevel/child/project.wiki.git/git-receive-pack", "application/x-git-receive-pack-request", true},
		{"POST", "/toplevel/child/project/snippets/123.git/git-receive-pack", "application/x-git-receive-pack-request", true},
		{"POST", "/snippets/123.git/git-receive-pack", "application/x-git-receive-pack-request", true},
		{"POST", "/foo/bar/git-receive-pack", "application/x-git-receive-pack-request", false},
		{"POST", "/foo/bar.git/git-zzz-pack", "application/x-git-receive-pack-request", false},
		{"POST", "/.git/git-receive-pack", "application/x-git-receive-pack-request", false},
		{"POST", "/toplevel.git/git-receive-pack", "application/x-git-upload-pack-request", false},
		{"GET", "/toplevel.git/git-receive-pack", "application/x-git-receive-pack-request", false},
	}

	for _, tc := range testCases {
		t.Run(tc.path, func(t *testing.T) {
			req, err := http.NewRequest(
				tc.method,
				ws.URL+tc.path,
				bytes.NewReader(testhelper.GitalyReceivePackResponseMock),
			)
			require.NoError(t, err)

			req.Header.Set("Content-Type", tc.contentType)

			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err)
			defer resp.Body.Close()

			body := string(testhelper.ReadAll(t, resp.Body))

			if tc.match {
				require.Equal(t, 200, resp.StatusCode)
				require.Contains(t, body, "\x00", "expect response generated by test gitaly server")
			} else {
				require.Equal(t, 204, resp.StatusCode)
				require.Empty(t, body, "normal request has empty response body")
			}
		})
	}
}

// ReaderFunc is an adapter to turn a conforming function into an io.Reader.
type ReaderFunc func(b []byte) (int, error)

func (r ReaderFunc) Read(b []byte) (int, error) { return r(b) }

func TestPostUploadPackProxiedToGitalySuccessfully(t *testing.T) {
	for i, tc := range []struct {
		showAllRefs bool
		code        codes.Code
	}{
		{true, codes.OK},
		{true, codes.Unavailable},
		{false, codes.OK},
		{false, codes.Unavailable},
	} {
		t.Run(fmt.Sprintf("Case %d", i), func(t *testing.T) {
			apiResponse := gitOkBody(t)
			apiResponse.ShowAllRefs = tc.showAllRefs

			gitalyServer, socketPath := startGitalyServer(t, tc.code)
			defer gitalyServer.GracefulStop()

			apiResponse.GitalyServer.Address = "unix:" + socketPath
			ts := testAuthServer(t, nil, nil, 200, apiResponse)
			defer ts.Close()

			ws := startWorkhorseServer(ts.URL)
			defer ws.Close()

			gitProtocol := "fake git protocol"
			resource := "/gitlab-org/gitlab-test.git/git-upload-pack"

			requestReader := bytes.NewReader(testhelper.GitalyUploadPackResponseMock)
			var m sync.Mutex
			requestReadFinished := false
			resp := httpPost(
				t,
				ws.URL+resource,
				map[string]string{
					"Content-Type": "application/x-git-upload-pack-request",
					"Git-Protocol": gitProtocol,
				},
				ReaderFunc(func(b []byte) (int, error) {
					n, err := requestReader.Read(b)
					if err != nil {
						m.Lock()
						requestReadFinished = true
						m.Unlock()
					}
					return n, err
				}),
			)
			defer resp.Body.Close()
			require.Equal(t, 200, resp.StatusCode, "POST %q", resource)
			testhelper.RequireResponseHeader(t, resp, "Content-Type", "application/x-git-upload-pack-result")

			m.Lock()
			requestFinished := requestReadFinished
			m.Unlock()
			require.True(t, requestFinished, "response written before request was fully read")

			body := string(testhelper.ReadAll(t, resp.Body))
			bodySplit := strings.SplitN(body, "\000", 2)
			require.Len(t, bodySplit, 2)

			gitalyRequest := &gitalypb.PostUploadPackRequest{}
			require.NoError(t, jsonpb.UnmarshalString(bodySplit[0], gitalyRequest))

			require.Equal(t, apiResponse.Repository.StorageName, gitalyRequest.Repository.StorageName)
			require.Equal(t, apiResponse.Repository.RelativePath, gitalyRequest.Repository.RelativePath)
			require.Equal(t, gitProtocol, gitalyRequest.GitProtocol)

			if tc.showAllRefs {
				require.Equal(t, []string{git.GitConfigShowAllRefs}, gitalyRequest.GitConfigOptions)
			} else {
				require.Empty(t, gitalyRequest.GitConfigOptions)
			}

			require.Equal(t, string(testhelper.GitalyUploadPackResponseMock), bodySplit[1], "POST %q: response body", resource)
		})
	}
}

func TestPostUploadPackProxiedToGitalyInterrupted(t *testing.T) {
	apiResponse := gitOkBody(t)

	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	apiResponse.GitalyServer.Address = "unix:" + socketPath
	ts := testAuthServer(t, nil, nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	resource := "/gitlab-org/gitlab-test.git/git-upload-pack"
	resp, err := http.Post(
		ws.URL+resource,
		"application/x-git-upload-pack-request",
		bytes.NewReader(testhelper.GitalyUploadPackResponseMock),
	)
	require.NoError(t, err)
	require.Equal(t, 200, resp.StatusCode, "POST %q", resource)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	waitDone(t, done)
}

func TestPostUploadPackRouting(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	apiResponse := gitOkBody(t)
	apiResponse.GitalyServer.Address = "unix:" + socketPath
	ts := testAuthServer(t, nil, nil, 200, apiResponse)
	defer ts.Close()

	ws := startWorkhorseServer(ts.URL)
	defer ws.Close()

	testCases := []struct {
		method      string
		path        string
		contentType string
		match       bool
	}{
		{"POST", "/toplevel.git/git-upload-pack", "application/x-git-upload-pack-request", true},
		{"POST", "/toplevel.wiki.git/git-upload-pack", "application/x-git-upload-pack-request", true},
		{"POST", "/toplevel/child/project.git/git-upload-pack", "application/x-git-upload-pack-request", true},
		{"POST", "/toplevel/child/project.wiki.git/git-upload-pack", "application/x-git-upload-pack-request", true},
		{"POST", "/toplevel/child/project/snippets/123.git/git-upload-pack", "application/x-git-upload-pack-request", true},
		{"POST", "/snippets/123.git/git-upload-pack", "application/x-git-upload-pack-request", true},
		{"POST", "/foo/bar/git-upload-pack", "application/x-git-upload-pack-request", false},
		{"POST", "/foo/bar.git/git-zzz-pack", "application/x-git-upload-pack-request", false},
		{"POST", "/.git/git-upload-pack", "application/x-git-upload-pack-request", false},
		{"POST", "/toplevel.git/git-upload-pack", "application/x-git-receive-pack-request", false},
		{"GET", "/toplevel.git/git-upload-pack", "application/x-git-upload-pack-request", false},
	}

	for _, tc := range testCases {
		t.Run(tc.path, func(t *testing.T) {
			req, err := http.NewRequest(
				tc.method,
				ws.URL+tc.path,
				bytes.NewReader(testhelper.GitalyReceivePackResponseMock),
			)
			require.NoError(t, err)

			req.Header.Set("Content-Type", tc.contentType)

			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err)
			defer resp.Body.Close()

			body := string(testhelper.ReadAll(t, resp.Body))

			if tc.match {
				require.Equal(t, 200, resp.StatusCode)
				require.Contains(t, body, "\x00", "expect response generated by test gitaly server")
			} else {
				require.Equal(t, 204, resp.StatusCode)
				require.Empty(t, body, "normal request has empty response body")
			}
		})
	}
}

func TestGetDiffProxiedToGitalySuccessfully(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath
	repoStorage := "default"
	rightCommit := "e395f646b1499e8e0279445fc99a0596a65fab7e"
	leftCommit := "8a0f2ee90d940bfb0ba1e14e8214b0649056e4ab"
	repoRelativePath := "foo/bar.git"
	jsonParams := fmt.Sprintf(`{"GitalyServer":{"Address":"%s","Token":""},"RawDiffRequest":"{\"repository\":{\"storageName\":\"%s\",\"relativePath\":\"%s\"},\"rightCommitId\":\"%s\",\"leftCommitId\":\"%s\"}"}`,
		gitalyAddress, repoStorage, repoRelativePath, leftCommit, rightCommit)
	expectedBody := testhelper.GitalyGetDiffResponseMock

	resp, body, err := doSendDataRequest("/something", "git-diff", jsonParams)
	require.NoError(t, err)

	require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
	require.Equal(t, expectedBody, string(body), "GET %q: response body", resp.Request.URL)
}

func TestGetPatchProxiedToGitalySuccessfully(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath
	repoStorage := "default"
	rightCommit := "e395f646b1499e8e0279445fc99a0596a65fab7e"
	leftCommit := "8a0f2ee90d940bfb0ba1e14e8214b0649056e4ab"
	repoRelativePath := "foo/bar.git"
	jsonParams := fmt.Sprintf(`{"GitalyServer":{"Address":"%s","Token":""},"RawPatchRequest":"{\"repository\":{\"storageName\":\"%s\",\"relativePath\":\"%s\"},\"rightCommitId\":\"%s\",\"leftCommitId\":\"%s\"}"}`,
		gitalyAddress, repoStorage, repoRelativePath, leftCommit, rightCommit)
	expectedBody := testhelper.GitalyGetPatchResponseMock

	resp, body, err := doSendDataRequest("/something", "git-format-patch", jsonParams)
	require.NoError(t, err)

	require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
	require.Equal(t, expectedBody, string(body), "GET %q: response body", resp.Request.URL)
}

func TestGetBlobProxiedToGitalyInterruptedStream(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath
	repoStorage := "default"
	oid := "54fcc214b94e78d7a41a9a8fe6d87a5e59500e51"
	repoRelativePath := "foo/bar.git"
	jsonParams := fmt.Sprintf(`{"GitalyServer":{"Address":"%s","Token":""},"GetBlobRequest":{"repository":{"storage_name":"%s","relative_path":"%s"},"oid":"%s","limit":-1}}`,
		gitalyAddress, repoStorage, repoRelativePath, oid)

	resp, _, err := doSendDataRequest("/something", "git-blob", jsonParams)
	require.NoError(t, err)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	waitDone(t, done)
}

func TestGetArchiveProxiedToGitalySuccessfully(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath
	repoStorage := "default"
	oid := "54fcc214b94e78d7a41a9a8fe6d87a5e59500e51"
	repoRelativePath := "foo/bar.git"
	archivePrefix := "repo-1"
	expectedBody := testhelper.GitalyGetArchiveResponseMock
	archiveLength := len(expectedBody)

	testCases := []struct {
		archivePath   string
		cacheDisabled bool
	}{
		{archivePath: path.Join(scratchDir, "my/path"), cacheDisabled: false},
		{archivePath: "/var/empty/my/path", cacheDisabled: true},
	}

	for _, tc := range testCases {
		jsonParams := fmt.Sprintf(`{"GitalyServer":{"Address":"%s","Token":""},"GitalyRepository":{"storage_name":"%s","relative_path":"%s"},"ArchivePath":"%s","ArchivePrefix":"%s","CommitId":"%s","DisableCache":%v}`,
			gitalyAddress, repoStorage, repoRelativePath, tc.archivePath, archivePrefix, oid, tc.cacheDisabled)
		resp, body, err := doSendDataRequest("/archive.tar.gz", "git-archive", jsonParams)
		require.NoError(t, err)

		require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
		require.Equal(t, expectedBody, string(body), "GET %q: response body", resp.Request.URL)
		require.Equal(t, archiveLength, len(body), "GET %q: body size", resp.Request.URL)

		if tc.cacheDisabled {
			_, err := os.Stat(tc.archivePath)
			require.True(t, os.IsNotExist(err), "expected 'does not exist', got: %v", err)
		} else {
			cachedArchive, err := ioutil.ReadFile(tc.archivePath)
			require.NoError(t, err)
			require.Equal(t, expectedBody, string(cachedArchive))
		}
	}
}

func TestGetArchiveProxiedToGitalyInterruptedStream(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath
	repoStorage := "default"
	oid := "54fcc214b94e78d7a41a9a8fe6d87a5e59500e51"
	repoRelativePath := "foo/bar.git"
	archivePath := "my/path"
	archivePrefix := "repo-1"
	jsonParams := fmt.Sprintf(`{"GitalyServer":{"Address":"%s","Token":""},"GitalyRepository":{"storage_name":"%s","relative_path":"%s"},"ArchivePath":"%s","ArchivePrefix":"%s","CommitId":"%s"}`,
		gitalyAddress, repoStorage, repoRelativePath, path.Join(scratchDir, archivePath), archivePrefix, oid)

	resp, _, err := doSendDataRequest("/archive.tar.gz", "git-archive", jsonParams)
	require.NoError(t, err)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	waitDone(t, done)
}

func TestGetDiffProxiedToGitalyInterruptedStream(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath
	repoStorage := "default"
	rightCommit := "e395f646b1499e8e0279445fc99a0596a65fab7e"
	leftCommit := "8a0f2ee90d940bfb0ba1e14e8214b0649056e4ab"
	repoRelativePath := "foo/bar.git"
	jsonParams := fmt.Sprintf(`{"GitalyServer":{"Address":"%s","Token":""},"RawDiffRequest":"{\"repository\":{\"storageName\":\"%s\",\"relativePath\":\"%s\"},\"rightCommitId\":\"%s\",\"leftCommitId\":\"%s\"}"}`,
		gitalyAddress, repoStorage, repoRelativePath, leftCommit, rightCommit)

	resp, _, err := doSendDataRequest("/something", "git-diff", jsonParams)
	require.NoError(t, err)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	waitDone(t, done)
}

func TestGetPatchProxiedToGitalyInterruptedStream(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath
	repoStorage := "default"
	rightCommit := "e395f646b1499e8e0279445fc99a0596a65fab7e"
	leftCommit := "8a0f2ee90d940bfb0ba1e14e8214b0649056e4ab"
	repoRelativePath := "foo/bar.git"
	jsonParams := fmt.Sprintf(`{"GitalyServer":{"Address":"%s","Token":""},"RawPatchRequest":"{\"repository\":{\"storageName\":\"%s\",\"relativePath\":\"%s\"},\"rightCommitId\":\"%s\",\"leftCommitId\":\"%s\"}"}`,
		gitalyAddress, repoStorage, repoRelativePath, leftCommit, rightCommit)

	resp, _, err := doSendDataRequest("/something", "git-format-patch", jsonParams)
	require.NoError(t, err)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	waitDone(t, done)
}

func TestGetSnapshotProxiedToGitalySuccessfully(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath
	expectedBody := testhelper.GitalyGetSnapshotResponseMock
	archiveLength := len(expectedBody)

	params := buildGetSnapshotParams(gitalyAddress, buildPbRepo("default", "foo/bar.git"))
	resp, body, err := doSendDataRequest("/api/v4/projects/:id/snapshot", "git-snapshot", params)
	require.NoError(t, err)

	require.Equal(t, http.StatusOK, resp.StatusCode, "GET %q: status code", resp.Request.URL)
	require.Equal(t, expectedBody, string(body), "GET %q: body", resp.Request.URL)
	require.Equal(t, archiveLength, len(body), "GET %q: body size", resp.Request.URL)

	testhelper.RequireResponseHeader(t, resp, "Content-Disposition", `attachment; filename="snapshot.tar"`)
	testhelper.RequireResponseHeader(t, resp, "Content-Type", "application/x-tar")
	testhelper.RequireResponseHeader(t, resp, "Content-Transfer-Encoding", "binary")
	testhelper.RequireResponseHeader(t, resp, "Cache-Control", "private")
}

func TestGetSnapshotProxiedToGitalyInterruptedStream(t *testing.T) {
	gitalyServer, socketPath := startGitalyServer(t, codes.OK)
	defer gitalyServer.GracefulStop()

	gitalyAddress := "unix:" + socketPath

	params := buildGetSnapshotParams(gitalyAddress, buildPbRepo("default", "foo/bar.git"))
	resp, _, err := doSendDataRequest("/api/v4/projects/:id/snapshot", "git-snapshot", params)
	require.NoError(t, err)

	// This causes the server stream to be interrupted instead of consumed entirely.
	resp.Body.Close()

	done := make(chan struct{})
	go func() {
		gitalyServer.WaitGroup.Wait()
		close(done)
	}()

	waitDone(t, done)
}

func buildGetSnapshotParams(gitalyAddress string, repo *gitalypb.Repository) string {
	msg := serializedMessage("GetSnapshotRequest", &gitalypb.GetSnapshotRequest{Repository: repo})
	return buildGitalyRPCParams(gitalyAddress, msg)
}

type rpcArg struct {
	k string
	v interface{}
}

// Gitlab asks workhorse to perform some long-running RPCs for it by sending
// the RPC arguments (which are protobuf messages) in HTTP response headers.
// The messages are encoded to JSON objects using pbjson, The strings are then
// re-encoded to JSON strings using json. We must replicate this behaviour here
func buildGitalyRPCParams(gitalyAddress string, rpcArgs ...rpcArg) string {
	built := map[string]interface{}{
		"GitalyServer": map[string]string{
			"Address": gitalyAddress,
			"Token":   "",
		},
	}

	for _, arg := range rpcArgs {
		built[arg.k] = arg.v
	}

	b, err := json.Marshal(interface{}(built))
	if err != nil {
		panic(err)
	}

	return string(b)
}

func buildPbRepo(storageName, relativePath string) *gitalypb.Repository {
	return &gitalypb.Repository{
		StorageName:  storageName,
		RelativePath: relativePath,
	}
}

func serializedMessage(name string, arg proto.Message) rpcArg {
	m := &jsonpb.Marshaler{}
	str, err := m.MarshalToString(arg)
	if err != nil {
		panic(err)
	}

	return rpcArg{name, str}
}

func serializedProtoMessage(name string, arg proto.Message) rpcArg {
	msg, err := proto.Marshal(arg)

	if err != nil {
		panic(err)
	}

	return rpcArg{name, base64.URLEncoding.EncodeToString(msg)}
}

type combinedServer struct {
	*grpc.Server
	*testhelper.GitalyTestServer
}

func startGitalyServer(t *testing.T, finalMessageCode codes.Code) (*combinedServer, string) {
	socketPath := path.Join(scratchDir, fmt.Sprintf("gitaly-%d.sock", rand.Int()))
	if err := os.Remove(socketPath); err != nil && !os.IsNotExist(err) {
		t.Fatal(err)
	}
	server := grpc.NewServer()
	listener, err := net.Listen("unix", socketPath)
	require.NoError(t, err)

	gitalyServer := testhelper.NewGitalyServer(finalMessageCode)
	gitalypb.RegisterSmartHTTPServiceServer(server, gitalyServer)
	gitalypb.RegisterBlobServiceServer(server, gitalyServer)
	gitalypb.RegisterRepositoryServiceServer(server, gitalyServer)
	gitalypb.RegisterDiffServiceServer(server, gitalyServer)

	go server.Serve(listener)

	return &combinedServer{Server: server, GitalyTestServer: gitalyServer}, socketPath
}

package upstream

import (
	"bytes"
	"net/http"
	"net/http/httptest"
	"sync/atomic"
	"testing"

	"github.com/redis/go-redis/v9"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

func TestAdminGeoPathsWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"Regular admin/geo", "/admin/geo", "Geo primary received request to path /admin/geo"},
		{"Specific object replication", "/admin/geo/replication/object_type", "Geo primary received request to path /admin/geo/replication/object_type"},
		{"Specific object replication per-site", "/admin/geo/sites/2/replication/object_type", "Geo primary received request to path /admin/geo/sites/2/replication/object_type"},
		{"Projects replication per-site", "/admin/geo/sites/2/replication/projects", "Geo primary received request to path /admin/geo/sites/2/replication/projects"},
		{"Designs replication per-site", "/admin/geo/sites/2/replication/designs", "Geo primary received request to path /admin/geo/sites/2/replication/designs"},
		{"Projects replication", "/admin/geo/replication/projects", "Local Rails server received request to path /admin/geo/replication/projects"},
		{"Projects replication subpaths", "/admin/geo/replication/projects/2", "Local Rails server received request to path /admin/geo/replication/projects/2"},
		{"Designs replication", "/admin/geo/replication/designs", "Local Rails server received request to path /admin/geo/replication/designs"},
		{"Designs replication subpaths", "/admin/geo/replication/designs/3", "Local Rails server received request to path /admin/geo/replication/designs/3"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestApiGeoPathsWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"Geo replication endpoint", "/api/v4/geo_replication", "Local Rails server received request to path /api/v4/geo_replication"},
		{"Geo GraphQL endpoint", "/api/v4/geo/graphql", "Local Rails server received request to path /api/v4/geo/graphql"},
		{"Current geo node failures", "/api/v4/geo_nodes/current/failures", "Local Rails server received request to path /api/v4/geo_nodes/current/failures"},
		{"Current geo sites failures", "/api/v4/geo_sites/current/failures", "Local Rails server received request to path /api/v4/geo_sites/current/failures"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestProjectNotExistingGitHttpPullWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"secondary info/refs", "/group/project.git/info/refs", "Local Rails server received request to path /group/project.git/info/refs"},
		{"primary info/refs", "/-/from_secondary/2/group/project.git/info/refs", "Geo primary received request to path /-/from_secondary/2/group/project.git/info/refs"},
		{"primary upload-pack", "/-/from_secondary/2/group/project.git/git-upload-pack", "Geo primary received request to path /-/from_secondary/2/group/project.git/git-upload-pack"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestProjectNotExistingGitHttpPushWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"secondary info/refs", "/group/project.git/info/refs", "Local Rails server received request to path /group/project.git/info/refs"},
		{"primary info/refs", "/-/from_secondary/2/group/project.git/info/refs", "Geo primary received request to path /-/from_secondary/2/group/project.git/info/refs"},
		{"primary receive-pack", "/-/from_secondary/2/group/project.git/git-receive-pack", "Geo primary received request to path /-/from_secondary/2/group/project.git/git-receive-pack"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestProjectNotExistingGitSSHPullWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"GitLab Shell call to authorized-keys", "/api/v4/internal/authorized_keys", "Local Rails server received request to path /api/v4/internal/authorized_keys"},
		{"GitLab Shell call to allowed", "/api/v4/internal/allowed", "Local Rails server received request to path /api/v4/internal/allowed"},
		{"GitLab Shell call to info/refs", "/api/v4/geo/proxy_git_ssh/info_refs_receive_pack", "Local Rails server received request to path /api/v4/geo/proxy_git_ssh/info_refs_receive_pack"},
		{"GitLab Shell call to receive_pack", "/api/v4/geo/proxy_git_ssh/receive_pack", "Local Rails server received request to path /api/v4/geo/proxy_git_ssh/receive_pack"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestProjectNotExistingGitSSHPushWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"GitLab Shell call to authorized-keys", "/api/v4/internal/authorized_keys", "Local Rails server received request to path /api/v4/internal/authorized_keys"},
		{"GitLab Shell call to allowed", "/api/v4/internal/allowed", "Local Rails server received request to path /api/v4/internal/allowed"},
		{"GitLab Shell call to info/refs", "/api/v4/geo/proxy_git_ssh/info_refs_upload_pack", "Local Rails server received request to path /api/v4/geo/proxy_git_ssh/info_refs_upload_pack"},
		{"GitLab Shell call to receive_pack", "/api/v4/geo/proxy_git_ssh/upload_pack", "Local Rails server received request to path /api/v4/geo/proxy_git_ssh/upload_pack"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestAssetsServedLocallyWithGeoProxy(t *testing.T) {
	path := "/assets/static.txt"
	content := "local geo asset"
	testhelper.SetupStaticFileHelper(t, path, content, testDocumentRoot)

	testCases := []testCase{
		{"assets path", "/assets/static.txt", "local geo asset"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestLfsBatchSecondaryGitSSHPullWithGeoProxy(t *testing.T) {
	body := bytes.NewBuffer([]byte(`{"operation":"download","objects": [{"oid":"fakeoid", "size":10}], "transfers":["basic", "ssh","lfs-standalone-file"],"ref":{"name":"refs/heads/fakeref"},"hash_algo":"sha256"}`))
	contentType := "application/vnd.git-lfs+json; charset=utf-8"
	testCases := []testCasePost{
		{testCase{"GitLab Shell call to /group/project.git/info/lfs/objects/batch", "/group/project.git/info/lfs/objects/batch", "Local Rails server received request to path /group/project.git/info/lfs/objects/batch"}, contentType, body},
	}

	runTestCasesWithGeoProxyEnabledPost(t, testCases)
}

func TestAllowedProxyRoute(t *testing.T) {
	testCases := []testCasePost{
		{testCase{"POST to /api/v4/internal/allowed", "/api/v4/internal/allowed", "Local Rails server received request to path /api/v4/internal/allowed"}, "application/json", nil},
	}

	railsServer := startRailsServer(t, nil)

	ws, _ := startWorkhorseServer(t, railsServer.URL, true)

	runTestCasesPost(t, ws, testCases)
}

func TestAllowedProxyRouteWithRateLimitCache(t *testing.T) {
	var requestCount atomic.Int32
	railsServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, _ *http.Request) {
		current := requestCount.Add(1)
		if current <= 2 {
			w.Header().Set("Enable-Workhorse-Circuit-Breaker", "true")
			w.Header().Set("Retry-After", "60")
			w.WriteHeader(http.StatusTooManyRequests)
		} else {
			w.WriteHeader(http.StatusOK)
		}
	}))
	defer railsServer.Close()

	rdb := initRdb(t)

	config := newUpstreamConfig(railsServer.URL)
	config.CircuitBreakerConfig.Enabled = true

	upstreamHandler := newUpstream(*config, testDependencies(t, withRdb(rdb)), configureRoutes)
	ws := httptest.NewServer(upstreamHandler)
	defer ws.Close()

	// The first request receives a 429 from the server with Retry-After header,
	// which caches the block for this user.
	// Subsequent should be blocked by the cache and not reach the server.
	for range 3 {
		resp, err := http.Post(ws.URL+"/api/v4/internal/allowed", "application/json",
			bytes.NewBufferString(`{"key_id":"test_key"}`))

		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusTooManyRequests, resp.StatusCode)
	}
}

// testRedisDB is the Redis database number used by this package's tests.
// Each package uses a unique number to avoid interference when tests run in parallel.
const testRedisDB = 3

func initRdb(t *testing.T) *redis.Client {
	return testhelper.SetupRedis(t, testRedisDB)
}

func TestWsRoutesRequireWebsocketUpgrade(t *testing.T) {
	railsServer := startRailsServer(t, nil)
	ws, _ := startWorkhorseServer(t, railsServer.URL, false)

	wsRoutes := []struct {
		name string
		path string
	}{
		{"ActionCable", "/-/cable"},
		{"environment terminal", "/group/project/-/environments/1/terminal.ws"},
		{"job terminal", "/group/project/-/jobs/123/terminal.ws"},
		{"job proxy", "/group/project/-/jobs/456/proxy.ws"},
		{"Duo Workflow", "/api/v4/ai/duo_workflows/ws"},
	}

	for _, route := range wsRoutes {
		t.Run(route.name+" rejects non-websocket request", func(t *testing.T) {
			resp, err := http.Get(ws.URL + route.path)
			require.NoError(t, err)
			defer resp.Body.Close()
			require.Equal(t, http.StatusBadRequest, resp.StatusCode)
		})

		t.Run(route.name+" allows websocket upgrade request", func(t *testing.T) {
			req, err := http.NewRequest("GET", ws.URL+route.path, nil)
			require.NoError(t, err)
			req.Header.Set("Connection", "upgrade")
			req.Header.Set("Upgrade", "websocket")

			resp, err := http.DefaultClient.Do(req)
			require.NoError(t, err)
			defer resp.Body.Close()
			require.Equal(t, http.StatusOK, resp.StatusCode)
		})
	}
}

func TestTerraformStateLockUnlockBodyLimit(t *testing.T) {
	railsServer := startRailsServer(t, nil)
	ws, _ := startWorkhorseServer(t, railsServer.URL, false)

	url := ws.URL + "/api/v4/projects/123/terraform/state/mystate/lock"

	tests := []struct {
		desc      string
		method    string
		smallBody string
	}{
		{"lock", http.MethodPost, `{"ID":"abc","Operation":"OperationTypePlan","Info":"","Who":"user","Version":"1.5.0","Created":"2024-01-01T00:00:00Z","Path":""}`},
		{"unlock", http.MethodDelete, `{"ID":"abc"}`},
	}

	for _, tt := range tests {
		t.Run(tt.desc, func(t *testing.T) {
			t.Run("small body is allowed", func(t *testing.T) {
				req, err := http.NewRequest(tt.method, url, bytes.NewReader([]byte(tt.smallBody)))
				require.NoError(t, err)
				req.Header.Set("Content-Type", "application/json")

				resp, err := http.DefaultClient.Do(req)
				require.NoError(t, err)
				defer resp.Body.Close()

				require.Equal(t, http.StatusOK, resp.StatusCode)
			})

			t.Run("oversized body is rejected with 413 Request Entity Too Large", func(t *testing.T) {
				req, err := http.NewRequest(tt.method, url, bytes.NewReader(bytes.Repeat([]byte("a"), 5*1024)))
				require.NoError(t, err)
				req.Header.Set("Content-Type", "application/json")

				resp, err := http.DefaultClient.Do(req)
				require.NoError(t, err)
				defer resp.Body.Close()

				require.Equal(t, http.StatusRequestEntityTooLarge, resp.StatusCode)
			})
		})
	}
}

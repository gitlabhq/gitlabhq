package upstream

import (
	"bytes"
	"context"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"testing"

	"github.com/redis/go-redis/v9"
	"github.com/sirupsen/logrus"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"

	configRedis "gitlab.com/gitlab-org/gitlab/workhorse/internal/redis"
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

func TestAllowedProxyRouteWithCircuitBreaker(t *testing.T) {
	const consecutiveFailures = 0
	var requestCount int
	railsServer := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		if requestCount <= 2 {
			w.Header().Set("Enable-Workhorse-Circuit-Breaker", "true")
			w.WriteHeader(http.StatusTooManyRequests)
		} else {
			// Subsequent requests would succeed if they reached the server
			fmt.Fprint(w, "Local Rails server received request to path "+r.URL.Path)
		}
		requestCount++
	}))
	defer railsServer.Close()

	rdb := initRdb(t)

	config := newUpstreamConfig(railsServer.URL)
	config.CircuitBreakerConfig.Enabled = true
	config.CircuitBreakerConfig.ConsecutiveFailures = consecutiveFailures

	upstreamHandler := newUpstream(*config, logrus.StandardLogger(), configureRoutes, nil, rdb, nil)
	ws := httptest.NewServer(upstreamHandler)
	defer ws.Close()

	// The first request receives a 429 from the server, and tracks the user in the circuit breaker.
	// The second request receives a 429 from the server, and trips the circuit breaker.
	// The third request shouldn't make it to the server and pre-emptively responds with a 429.
	for range 3 {
		resp, err := http.Post(ws.URL+"/api/v4/internal/allowed", "application/json",
			bytes.NewBufferString(`{"key_id":"test_key"}`))

		require.NoError(t, err)
		defer resp.Body.Close()

		assert.Equal(t, http.StatusTooManyRequests, resp.StatusCode)
	}
}

func initRdb(t *testing.T) *redis.Client {
	buf, err := os.ReadFile("../../config.toml")
	require.NoError(t, err)
	cfg, err := config.LoadConfig(string(buf))
	require.NoError(t, err)
	rdb, err := configRedis.Configure(cfg)
	require.NoError(t, err)
	t.Cleanup(func() {
		rdb.FlushAll(context.Background())
		assert.NoError(t, rdb.Close())
	})
	return rdb
}

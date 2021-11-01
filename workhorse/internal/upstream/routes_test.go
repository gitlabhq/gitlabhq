package upstream

import (
	"testing"
)

func TestProjectNotExistingGitHttpPullWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"secondary info/refs", "/group/project.git/info/refs", "Local Rails server received request to path /group/project.git/info/refs"},
		{"primary info/refs", "/-/push_from_secondary/2/group/project.git/info/refs", "Geo primary received request to path /-/push_from_secondary/2/group/project.git/info/refs"},
		{"primary upload-pack", "/-/push_from_secondary/2/group/project.git/git-upload-pack", "Geo primary received request to path /-/push_from_secondary/2/group/project.git/git-upload-pack"},
	}

	runTestCasesWithGeoProxyEnabled(t, testCases)
}

func TestProjectNotExistingGitHttpPushWithGeoProxy(t *testing.T) {
	testCases := []testCase{
		{"secondary info/refs", "/group/project.git/info/refs", "Local Rails server received request to path /group/project.git/info/refs"},
		{"primary info/refs", "/-/push_from_secondary/2/group/project.git/info/refs", "Geo primary received request to path /-/push_from_secondary/2/group/project.git/info/refs"},
		{"primary receive-pack", "/-/push_from_secondary/2/group/project.git/git-receive-pack", "Geo primary received request to path /-/push_from_secondary/2/group/project.git/git-receive-pack"},
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

// Tests in this file need access to a real Gitaly server to run. The address
// is supplied via the GITALY_ADDRESS environment variable
package main

import (
	"archive/tar"
	"bufio"
	"bytes"
	"context"
	"fmt"
	"net/url"
	"os"
	"os/exec"
	"path"
	"regexp"
	"strconv"
	"strings"
	"testing"

	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"
	"gitlab.com/gitlab-org/gitaly/v16/streamio"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

var (
	gitalyAddresses []string
)

const repo1 = "repo-1"

// Convert from tcp://127.0.0.1:8075 to dns scheme variants:
// * dns:127.0.0.1:8075
// * dns:///127.0.0.1:8075
func convertToDNSSchemes(address string) []string {
	uri, err := url.Parse(address)
	if err != nil {
		panic(fmt.Sprintf("invalid GITALY_ADDRESS url %s: %s", address, err))
	}
	return []string{
		fmt.Sprintf("dns:///%s", uri.Host),
		fmt.Sprintf("dns:%s", uri.Host),
	}
}

func jsonGitalyServer(address string) string {
	return fmt.Sprintf(`"GitalyServer":{"Address":"%s", "Token": ""}`, address)
}

func init() {
	rawAddress := os.Getenv("GITALY_ADDRESS")
	if rawAddress != "" {
		gitalyAddresses = append(gitalyAddresses, rawAddress)
		gitalyAddresses = append(gitalyAddresses, convertToDNSSchemes(rawAddress)...)
	}
}

func skipUnlessRealGitaly(t *testing.T) {
	t.Log(gitalyAddresses)
	if len(gitalyAddresses) != 0 {
		return
	}

	t.Skip(`Please set GITALY_ADDRESS="..." to run Gitaly integration tests`)
}

func realGitalyAuthResponse(gitalyAddress string, apiResponse *api.Response) *api.Response {
	apiResponse.GitalyServer.Address = gitalyAddress

	return apiResponse
}

func realGitalyOkBody(t *testing.T, gitalyAddress string) *api.Response {
	return realGitalyAuthResponse(gitalyAddress, gitOkBody(t))
}

func ensureGitalyRepository(_ *testing.T, apiResponse *api.Response) error {
	ctx, repository, err := gitaly.NewRepositoryClient(context.Background(), apiResponse.GitalyServer)
	if err != nil {
		return err
	}

	// Remove the repository if it already exists, for consistency
	if _, removeRepoErr := repository.RepositoryServiceClient.RemoveRepository(ctx, &gitalypb.RemoveRepositoryRequest{
		Repository: &gitalypb.Repository{
			StorageName:  apiResponse.Repository.StorageName,
			RelativePath: apiResponse.Repository.RelativePath,
		},
	}); removeRepoErr != nil {
		status, ok := status.FromError(removeRepoErr)
		if !ok || !(status.Code() == codes.NotFound && (status.Message() == "repository does not exist" || status.Message() == "repository not found")) {
			return fmt.Errorf("remove repository: %w", removeRepoErr)
		}

		// Repository didn't exist.
	}

	stream, err := repository.CreateRepositoryFromBundle(ctx)
	if err != nil {
		return fmt.Errorf("initiate stream: %w", err)
	}

	if err := stream.Send(&gitalypb.CreateRepositoryFromBundleRequest{Repository: &apiResponse.Repository}); err != nil {
		return err
	}

	gitBundle := exec.Command("git", "-C", path.Join(testRepoRoot, testRepo), "bundle", "create", "-", "--all")
	gitBundle.Stdout = streamio.NewWriter(func(p []byte) error {
		return stream.Send(&gitalypb.CreateRepositoryFromBundleRequest{Data: p})
	})

	if err := gitBundle.Run(); err != nil {
		return fmt.Errorf("run git bundle --create: %w", err)
	}
	if _, err := stream.CloseAndRecv(); err != nil {
		return fmt.Errorf("finish CreateRepositoryFromBundle: %w", err)
	}

	return nil
}

func TestAllowedClone(t *testing.T) {
	skipUnlessRealGitaly(t)

	for _, gitalyAddress := range gitalyAddresses {
		t.Run(gitalyAddress, func(t *testing.T) {
			// Create the repository in the Gitaly server
			apiResponse := realGitalyOkBody(t, gitalyAddress)
			require.NoError(t, ensureGitalyRepository(t, apiResponse))

			// Prepare test server and backend
			ts := testAuthServer(t, nil, nil, 200, apiResponse)
			ws := startWorkhorseServer(t, ts.URL)

			// Do the git clone
			tmpDir := t.TempDir()
			cloneCmd := exec.Command("git", "clone", fmt.Sprintf("%s/%s", ws.URL, testRepo), tmpDir)
			runOrFail(t, cloneCmd)

			// We may have cloned an 'empty' repository, 'git log' will fail in it
			logCmd := exec.Command("git", "log", "-1", "--oneline")
			logCmd.Dir = tmpDir
			runOrFail(t, logCmd)
		})
	}
}

func TestAllowedShallowClone(t *testing.T) {
	skipUnlessRealGitaly(t)

	for _, gitalyAddress := range gitalyAddresses {
		t.Run(gitalyAddress, func(t *testing.T) {
			// Create the repository in the Gitaly server
			apiResponse := realGitalyOkBody(t, gitalyAddress)
			require.NoError(t, ensureGitalyRepository(t, apiResponse))

			// Prepare test server and backend
			ts := testAuthServer(t, nil, nil, 200, apiResponse)
			ws := startWorkhorseServer(t, ts.URL)

			// Shallow git clone (depth 1)
			tmpDir := t.TempDir()
			cloneCmd := exec.Command("git", "clone", "--depth", "1", fmt.Sprintf("%s/%s", ws.URL, testRepo), tmpDir)
			runOrFail(t, cloneCmd)

			// We may have cloned an 'empty' repository, 'git log' will fail in it
			logCmd := exec.Command("git", "log", "-1", "--oneline")
			logCmd.Dir = tmpDir
			runOrFail(t, logCmd)
		})
	}
}

func TestAllowedPush(t *testing.T) {
	skipUnlessRealGitaly(t)

	for _, gitalyAddress := range gitalyAddresses {
		t.Run(gitalyAddress, func(t *testing.T) {
			// Create the repository in the Gitaly server
			apiResponse := realGitalyOkBody(t, gitalyAddress)
			require.NoError(t, ensureGitalyRepository(t, apiResponse))

			// Prepare the test server and backend
			ts := testAuthServer(t, nil, nil, 200, apiResponse)
			ws := startWorkhorseServer(t, ts.URL)

			// Do the git clone
			tmpDir := t.TempDir()
			cloneCmd := exec.Command("git", "clone", fmt.Sprintf("%s/%s", ws.URL, testRepo), tmpDir)
			runOrFail(t, cloneCmd)

			// Perform the git push
			pushCmd := exec.Command("git", "push", fmt.Sprintf("%s/%s", ws.URL, testRepo), fmt.Sprintf("master:%s", newBranch()))
			pushCmd.Dir = tmpDir
			runOrFail(t, pushCmd)
		})
	}
}

func TestAllowedGetGitBlob(t *testing.T) {
	skipUnlessRealGitaly(t)

	for _, gitalyAddress := range gitalyAddresses {
		t.Run(gitalyAddress, func(t *testing.T) {
			// Create the repository in the Gitaly server
			apiResponse := realGitalyOkBody(t, gitalyAddress)
			require.NoError(t, ensureGitalyRepository(t, apiResponse))

			// the LICENSE file in the test repository
			oid := "50b27c6518be44c42c4d87966ae2481ce895624c"
			expectedBody := "The MIT License (MIT)"
			bodyLen := 1075

			jsonParams := fmt.Sprintf(
				`{
				%s,
				"GetBlobRequest":{
					"repository":{"storage_name":"%s", "relative_path":"%s"},
					"oid":"%s",
					"limit":-1
				}
			}`,
				jsonGitalyServer(gitalyAddress), apiResponse.Repository.StorageName, apiResponse.Repository.RelativePath, oid,
			)

			resp, body, err := doSendDataRequest(t, "/something", "git-blob", jsonParams)
			defer func() { _ = resp.Body.Close() }()

			require.NoError(t, err)
			shortBody := string(body[:len(expectedBody)])

			require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
			require.Equal(t, expectedBody, shortBody, "GET %q: response body", resp.Request.URL)
			testhelper.RequireResponseHeader(t, resp, "Content-Length", strconv.Itoa(bodyLen))
			requireNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resp.Request.URL)
		})
	}
}

func TestAllowedGetGitArchive(t *testing.T) {
	skipUnlessRealGitaly(t)

	for _, gitalyAddress := range gitalyAddresses {
		t.Run(gitalyAddress, func(t *testing.T) {
			// Create the repository in the Gitaly server
			apiResponse := realGitalyOkBody(t, gitalyAddress)
			require.NoError(t, ensureGitalyRepository(t, apiResponse))

			archivePath := path.Join(t.TempDir(), "my/path")
			archivePrefix := repo1

			msg := serializedProtoMessage("GetArchiveRequest", &gitalypb.GetArchiveRequest{
				Repository: &apiResponse.Repository,
				CommitId:   "HEAD",
				Prefix:     archivePrefix,
				Format:     gitalypb.GetArchiveRequest_TAR,
				Path:       []byte("files"),
			})
			jsonParams := buildGitalyRPCParams(gitalyAddress, rpcArg{"ArchivePath", archivePath}, msg)

			resp, body, err := doSendDataRequest(t, "/archive.tar", "git-archive", jsonParams)
			defer func() { _ = resp.Body.Close() }()

			require.NoError(t, err)
			require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
			requireNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resp.Request.URL)

			// Ensure the tar file is readable
			foundEntry := false
			tr := tar.NewReader(bytes.NewReader(body))
			for {
				hdr, err := tr.Next()
				if err != nil {
					break
				}

				if hdr.Name == archivePrefix+"/" {
					foundEntry = true
					break
				}
			}

			require.True(t, foundEntry, "Couldn't find %v directory entry", archivePrefix)
		})
	}
}

func TestAllowedGetGitArchiveOldPayload(t *testing.T) {
	skipUnlessRealGitaly(t)

	for _, gitalyAddress := range gitalyAddresses {
		t.Run(gitalyAddress, func(t *testing.T) {
			// Create the repository in the Gitaly server
			apiResponse := realGitalyOkBody(t, gitalyAddress)
			repo := &apiResponse.Repository
			require.NoError(t, ensureGitalyRepository(t, apiResponse))

			archivePath := path.Join(t.TempDir(), "my/path")
			archivePrefix := repo1

			jsonParams := fmt.Sprintf(
				`{
			%s,
			"GitalyRepository":{"storage_name":"%s","relative_path":"%s"},
			"ArchivePath":"%s",
			"ArchivePrefix":"%s",
			"CommitId":"%s"
		}`,
				jsonGitalyServer(gitalyAddress), repo.StorageName, repo.RelativePath, archivePath, archivePrefix, "HEAD",
			)

			resp, body, err := doSendDataRequest(t, "/archive.tar", "git-archive", jsonParams)
			defer func() { _ = resp.Body.Close() }()

			require.NoError(t, err)
			require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
			requireNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resp.Request.URL)

			// Ensure the tar file is readable
			foundEntry := false
			tr := tar.NewReader(bytes.NewReader(body))
			for {
				hdr, err := tr.Next()
				if err != nil {
					break
				}

				if hdr.Name == archivePrefix+"/" {
					foundEntry = true
					break
				}
			}

			require.True(t, foundEntry, "Couldn't find %v directory entry", archivePrefix)
		})
	}
}

func TestAllowedGetGitDiff(t *testing.T) {
	skipUnlessRealGitaly(t)

	for _, gitalyAddress := range gitalyAddresses {
		t.Run(gitalyAddress, func(t *testing.T) {
			// Create the repository in the Gitaly server
			apiResponse := realGitalyOkBody(t, gitalyAddress)
			require.NoError(t, ensureGitalyRepository(t, apiResponse))

			msg := serializedMessage("RawDiffRequest", &gitalypb.RawDiffRequest{
				Repository:    &apiResponse.Repository,
				LeftCommitId:  "b0e52af38d7ea43cf41d8a6f2471351ac036d6c9",
				RightCommitId: "732401c65e924df81435deb12891ef570167d2e2",
			})
			jsonParams := buildGitalyRPCParams(gitalyAddress, msg)

			resp, body, err := doSendDataRequest(t, "/something", "git-diff", jsonParams)
			require.NoError(t, err)
			defer func() { _ = resp.Body.Close() }()

			require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
			requireNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resp.Request.URL)

			expectedBody := "diff --git a/LICENSE b/LICENSE\n"
			require.Equal(t, expectedBody, string(body[:len(expectedBody)]),
				"GET %q: response body", resp.Request.URL)
		})
	}
}

func TestAllowedGetGitFormatPatch(t *testing.T) {
	skipUnlessRealGitaly(t)

	for _, gitalyAddress := range gitalyAddresses {
		t.Run(gitalyAddress, func(t *testing.T) {
			// Create the repository in the Gitaly server
			apiResponse := realGitalyOkBody(t, gitalyAddress)
			require.NoError(t, ensureGitalyRepository(t, apiResponse))

			msg := serializedMessage("RawPatchRequest", &gitalypb.RawPatchRequest{
				Repository:    &apiResponse.Repository,
				LeftCommitId:  "b0e52af38d7ea43cf41d8a6f2471351ac036d6c9",
				RightCommitId: "0e1b353b348f8477bdbec1ef47087171c5032cd9",
			})
			jsonParams := buildGitalyRPCParams(gitalyAddress, msg)

			resp, body, err := doSendDataRequest(t, "/something", "git-format-patch", jsonParams)
			require.NoError(t, err)
			defer func() { _ = resp.Body.Close() }()

			require.Equal(t, 200, resp.StatusCode, "GET %q: status code", resp.Request.URL)
			requireNginxResponseBuffering(t, "no", resp, "GET %q: nginx response buffering", resp.Request.URL)

			requirePatchSeries(t, body,
				"732401c65e924df81435deb12891ef570167d2e2",
				"33bcff41c232a11727ac6d660bd4b0c2ba86d63d",
				"0e1b353b348f8477bdbec1ef47087171c5032cd9",
			)
		})
	}
}

var extractPatchSeriesMatcher = regexp.MustCompile(`^From (\w+)`)

// RequirePatchSeries takes a `git format-patch` blob, extracts the From xxxxx
// lines and compares the SHAs to expected list.
func requirePatchSeries(t *testing.T, blob []byte, expected ...string) {
	t.Helper()
	var actual []string
	footer := make([]string, 3)

	scanner := bufio.NewScanner(bytes.NewReader(blob))

	for scanner.Scan() {
		line := scanner.Text()
		if matches := extractPatchSeriesMatcher.FindStringSubmatch(line); len(matches) == 2 {
			actual = append(actual, matches[1])
		}
		footer = []string{footer[1], footer[2], line}
	}

	require.Equal(t, strings.Join(expected, "\n"), strings.Join(actual, "\n"), "patch series")

	// Check the last returned patch is complete
	// Don't assert on the final line, it is a git version
	require.Equal(t, "-- ", footer[0], "end of patch marker")
}

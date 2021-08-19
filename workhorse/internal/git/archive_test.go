package git

import (
	"io/ioutil"
	"net/http/httptest"
	"testing"

	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"

	"github.com/stretchr/testify/require"
)

func TestParseBasename(t *testing.T) {
	for _, testCase := range []struct {
		in  string
		out gitalypb.GetArchiveRequest_Format
	}{
		{"archive", gitalypb.GetArchiveRequest_TAR_GZ},
		{"master.tar.gz", gitalypb.GetArchiveRequest_TAR_GZ},
		{"foo-master.tgz", gitalypb.GetArchiveRequest_TAR_GZ},
		{"foo-v1.2.1.gz", gitalypb.GetArchiveRequest_TAR_GZ},
		{"foo.tar.bz2", gitalypb.GetArchiveRequest_TAR_BZ2},
		{"archive.tbz", gitalypb.GetArchiveRequest_TAR_BZ2},
		{"archive.tbz2", gitalypb.GetArchiveRequest_TAR_BZ2},
		{"archive.tb2", gitalypb.GetArchiveRequest_TAR_BZ2},
		{"archive.bz2", gitalypb.GetArchiveRequest_TAR_BZ2},
	} {
		basename := testCase.in
		out, ok := parseBasename(basename)
		if !ok {
			t.Fatalf("parseBasename did not recognize %q", basename)
		}

		if out != testCase.out {
			t.Fatalf("expected %q, got %q", testCase.out, out)
		}
	}
}

func TestFinalizeArchive(t *testing.T) {
	tempFile, err := ioutil.TempFile("", "gitlab-workhorse-test")
	if err != nil {
		t.Fatal(err)
	}
	defer tempFile.Close()

	// Deliberately cause an EEXIST error: we know tempFile.Name() already exists
	err = finalizeCachedArchive(tempFile, tempFile.Name())
	if err != nil {
		t.Fatalf("expected nil from finalizeCachedArchive, received %v", err)
	}
}

func TestSetArchiveHeaders(t *testing.T) {
	for _, testCase := range []struct {
		in  gitalypb.GetArchiveRequest_Format
		out string
	}{
		{gitalypb.GetArchiveRequest_ZIP, "application/zip"},
		{gitalypb.GetArchiveRequest_TAR, "application/octet-stream"},
		{gitalypb.GetArchiveRequest_TAR_GZ, "application/octet-stream"},
		{gitalypb.GetArchiveRequest_TAR_BZ2, "application/octet-stream"},
	} {
		w := httptest.NewRecorder()

		// These should be replaced, not appended to
		w.Header().Set("Content-Type", "test")
		w.Header().Set("Content-Length", "test")
		w.Header().Set("Content-Disposition", "test")

		// This should be deleted
		w.Header().Set("Set-Cookie", "test")

		// This should be preserved
		w.Header().Set("Cache-Control", "public, max-age=3600")

		setArchiveHeaders(w, testCase.in, "filename")

		testhelper.RequireResponseHeader(t, w, "Content-Type", testCase.out)
		testhelper.RequireResponseHeader(t, w, "Content-Length")
		testhelper.RequireResponseHeader(t, w, "Content-Disposition", `attachment; filename="filename"`)
		testhelper.RequireResponseHeader(t, w, "Cache-Control", "public, max-age=3600")
		require.Empty(t, w.Header().Get("Set-Cookie"), "remove Set-Cookie")
	}
}

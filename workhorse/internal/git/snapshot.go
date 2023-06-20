package git

import (
	"fmt"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
)

type snapshot struct {
	senddata.Prefix
}

type snapshotParams struct {
	GitalyServer       api.GitalyServer
	GetSnapshotRequest string
}

var (
	SendSnapshot = &snapshot{"git-snapshot:"}
)

func (s *snapshot) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params snapshotParams

	if err := s.Unpack(&params, sendData); err != nil {
		fail.Request(w, r, fmt.Errorf("SendSnapshot: unpack sendData: %v", err))
		return
	}

	request := &gitalypb.GetSnapshotRequest{}
	if err := gitaly.UnmarshalJSON(params.GetSnapshotRequest, request); err != nil {
		fail.Request(w, r, fmt.Errorf("SendSnapshot: unmarshal GetSnapshotRequest: %v", err))
		return
	}

	ctx, c, err := gitaly.NewRepositoryClient(r.Context(), params.GitalyServer)

	if err != nil {
		fail.Request(w, r, fmt.Errorf("SendSnapshot: gitaly.NewRepositoryClient: %v", err))
		return
	}

	reader, err := c.SnapshotReader(ctx, request)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("SendSnapshot: client.SnapshotReader: %v", err))
		return
	}

	w.Header().Del("Content-Length")
	w.Header().Set("Content-Disposition", `attachment; filename="snapshot.tar"`)
	w.Header().Set("Content-Type", "application/x-tar")
	w.Header().Set("Content-Transfer-Encoding", "binary")
	w.Header().Set("Cache-Control", "private")
	w.WriteHeader(http.StatusOK) // Errors aren't detectable beyond this point

	if _, err := io.Copy(w, reader); err != nil {
		log.WithRequest(r).WithError(fmt.Errorf("SendSnapshot: copy gitaly output: %v", err)).Error()
	}
}

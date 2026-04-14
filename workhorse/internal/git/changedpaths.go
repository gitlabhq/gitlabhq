package git

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitaly/v18/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
)

type changedPaths struct{ senddata.Prefix }
type changedPathsParams struct {
	GitalyServer            api.GitalyServer
	FindChangedPathsRequest string
}

// SendChangedPaths is a senddata.Injecter for streaming changed file paths from Gitaly.
var SendChangedPaths = &changedPaths{"git-changed-paths:"}

func (cp *changedPaths) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params changedPathsParams
	if err := cp.Unpack(&params, sendData); err != nil {
		fail.Request(w, r, fmt.Errorf("SendChangedPaths: unpack sendData: %v", err))
		return
	}

	request := &gitalypb.FindChangedPathsRequest{}
	if err := gitaly.UnmarshalJSON(params.FindChangedPathsRequest, request); err != nil {
		fail.Request(w, r, fmt.Errorf("SendChangedPaths: unmarshal request: %v", err))
		return
	}

	ctx, diffClient, err := gitaly.NewDiffClient(r.Context(), params.GitalyServer)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("SendChangedPaths: create client: %v", err))
		return
	}

	if err := diffClient.SendFindChangedPaths(ctx, w, request); err != nil {
		log.WithRequest(r).WithError(&copyError{fmt.Errorf("SendChangedPaths: %v", err)}).Error()
		return
	}
}

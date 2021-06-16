package git

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab-workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab-workhorse/internal/senddata"
)

type patch struct{ senddata.Prefix }
type patchParams struct {
	GitalyServer    gitaly.Server
	RawPatchRequest string
}

var SendPatch = &patch{"git-format-patch:"}

func (p *patch) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params patchParams
	if err := p.Unpack(&params, sendData); err != nil {
		helper.Fail500(w, r, fmt.Errorf("SendPatch: unpack sendData: %v", err))
		return
	}

	request := &gitalypb.RawPatchRequest{}
	if err := gitaly.UnmarshalJSON(params.RawPatchRequest, request); err != nil {
		helper.Fail500(w, r, fmt.Errorf("diff.RawPatch: %v", err))
		return
	}

	ctx, diffClient, err := gitaly.NewDiffClient(r.Context(), params.GitalyServer)
	if err != nil {
		helper.Fail500(w, r, fmt.Errorf("diff.RawPatch: %v", err))
		return
	}

	if err := diffClient.SendRawPatch(ctx, w, request); err != nil {
		log.WithRequest(r).WithError(&copyError{fmt.Errorf("diff.RawPatch: %v", err)}).Error()
		return
	}
}

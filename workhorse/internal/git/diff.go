package git

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitaly/v14/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
)

type diff struct{ senddata.Prefix }
type diffParams struct {
	GitalyServer   gitaly.Server
	RawDiffRequest string
}

var SendDiff = &diff{"git-diff:"}

func (d *diff) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params diffParams
	if err := d.Unpack(&params, sendData); err != nil {
		helper.Fail500(w, r, fmt.Errorf("SendDiff: unpack sendData: %v", err))
		return
	}

	request := &gitalypb.RawDiffRequest{}
	if err := gitaly.UnmarshalJSON(params.RawDiffRequest, request); err != nil {
		helper.Fail500(w, r, fmt.Errorf("diff.RawDiff: %v", err))
		return
	}

	ctx, diffClient, err := gitaly.NewDiffClient(r.Context(), params.GitalyServer)
	if err != nil {
		helper.Fail500(w, r, fmt.Errorf("diff.RawDiff: %v", err))
		return
	}

	if err := diffClient.SendRawDiff(ctx, w, request); err != nil {
		log.WithRequest(r).WithError(&copyError{fmt.Errorf("diff.RawDiff: %v", err)}).Error()
		return
	}
}

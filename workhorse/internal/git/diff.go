package git

import (
	"fmt"
	"net/http"

	"gitlab.com/gitlab-org/gitaly/v16/proto/go/gitalypb"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/gitaly"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/senddata"
)

type diff struct{ senddata.Prefix }
type diffParams struct {
	GitalyServer   api.GitalyServer
	RawDiffRequest string
}

var SendDiff = &diff{"git-diff:"}

func (d *diff) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params diffParams
	if err := d.Unpack(&params, sendData); err != nil {
		fail.Request(w, r, fmt.Errorf("SendDiff: unpack sendData: %v", err))
		return
	}

	request := &gitalypb.RawDiffRequest{}
	if err := gitaly.UnmarshalJSON(params.RawDiffRequest, request); err != nil {
		fail.Request(w, r, fmt.Errorf("diff.RawDiff: %v", err))
		return
	}

	ctx, diffClient, err := gitaly.NewDiffClient(r.Context(), params.GitalyServer)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("diff.RawDiff: %v", err))
		return
	}

	if err := diffClient.SendRawDiff(ctx, w, request); err != nil {
		log.WithRequest(r).WithError(&copyError{fmt.Errorf("diff.RawDiff: %v", err)}).Error()
		return
	}
}

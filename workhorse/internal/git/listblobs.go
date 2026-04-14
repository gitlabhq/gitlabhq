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

type listBlobs struct{ senddata.Prefix }
type listBlobsParams struct {
	GitalyServer     api.GitalyServer
	ListBlobsRequest string
}

// SendListBlobs is a senddata.Injecter for streaming blob contents from Gitaly.
var SendListBlobs = &listBlobs{"git-list-blobs:"}

func (lb *listBlobs) Inject(w http.ResponseWriter, r *http.Request, sendData string) {
	var params listBlobsParams
	if err := lb.Unpack(&params, sendData); err != nil {
		fail.Request(w, r, fmt.Errorf("SendListBlobs: unpack sendData: %v", err))
		return
	}

	request := &gitalypb.ListBlobsRequest{}
	if err := gitaly.UnmarshalJSON(params.ListBlobsRequest, request); err != nil {
		fail.Request(w, r, fmt.Errorf("SendListBlobs: unmarshal request: %v", err))
		return
	}

	ctx, blobClient, err := gitaly.NewBlobClient(r.Context(), params.GitalyServer)
	if err != nil {
		fail.Request(w, r, fmt.Errorf("SendListBlobs: create client: %v", err))
		return
	}

	if err := blobClient.SendListBlobs(ctx, w, request); err != nil {
		log.WithRequest(r).WithError(&copyError{fmt.Errorf("SendListBlobs: %v", err)}).Error()
		return
	}
}

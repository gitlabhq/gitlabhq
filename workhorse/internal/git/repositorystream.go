package git

import (
	"errors"
	"net/http"
	"strings"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper/fail"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/log"
)

// FindChangedPaths reports a missing revision as codes.NotFound, but ListBlobs
// wraps the rev-list failure as codes.Internal, so there the git stderr text is
// the only signal.
var unknownObjectMessages = []string{"bad object", "bad revision", "not a valid object", "missing object"}

func failRepositoryStream(response helper.CountingResponseWriter, request *http.Request, streamError error) {
	if response.Status() != 0 {
		log.WithRequest(request).WithError(&copyError{streamError}).Error()
		panic(http.ErrAbortHandler)
	}

	response.Header().Del("Content-Type")

	if gitalyMessage, unknownObject := unknownObjectMessage(streamError); unknownObject {
		fail.Request(response, request, streamError, fail.WithStatus(http.StatusNotFound), fail.WithBody(gitalyMessage))
		return
	}

	fail.Request(response, request, streamError)
}

func unknownObjectMessage(streamError error) (string, bool) {
	var gitalyError interface{ GRPCStatus() *status.Status }
	if !errors.As(streamError, &gitalyError) {
		return "", false
	}

	gitalyStatus := gitalyError.GRPCStatus()
	gitalyMessage := gitalyStatus.Message()
	if gitalyStatus.Code() == codes.NotFound {
		return gitalyMessage, true
	}

	for _, marker := range unknownObjectMessages {
		if strings.Contains(gitalyMessage, marker) {
			return gitalyMessage, true
		}
	}

	return "", false
}

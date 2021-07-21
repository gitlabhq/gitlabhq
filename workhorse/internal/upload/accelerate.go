package upload

import (
	"fmt"
	"net/http"

	"github.com/dgrijalva/jwt-go"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

const RewrittenFieldsHeader = "Gitlab-Workhorse-Multipart-Fields"

type MultipartClaims struct {
	RewrittenFields map[string]string `json:"rewritten_fields"`
	jwt.StandardClaims
}

func Accelerate(rails PreAuthorizer, h http.Handler, p Preparer) http.Handler {
	return rails.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		s := &SavedFileTracker{Request: r}

		opts, _, err := p.Prepare(a)
		if err != nil {
			helper.Fail500(w, r, fmt.Errorf("Accelerate: error preparing file storage options"))
			return
		}

		HandleFileUploads(w, r, h, a, s, opts)
	}, "/authorize")
}

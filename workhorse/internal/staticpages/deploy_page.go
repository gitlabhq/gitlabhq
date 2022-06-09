package staticpages

import (
	"net/http"
	"os"
	"path/filepath"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

func (s *Static) DeployPage(handler http.Handler) http.Handler {
	deployPage := filepath.Join(s.DocumentRoot, "index.html")

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		data, err := os.ReadFile(deployPage)
		if err != nil {
			handler.ServeHTTP(w, r)
			return
		}

		helper.SetNoCacheHeaders(w.Header())
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		w.Write(data)
	})
}

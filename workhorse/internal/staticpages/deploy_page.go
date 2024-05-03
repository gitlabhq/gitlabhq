// Package staticpages provides functionality for serving static pages and handling errors.
package staticpages

import (
	"fmt"
	"net/http"
	"os"
	"path/filepath"
)

// DeployPage deploys the index.html page by serving it using the provided handler.
func (s *Static) DeployPage(handler http.Handler) http.Handler {
	deployPage := filepath.Join(s.DocumentRoot, "index.html")

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		cleanURL := filepath.Clean(deployPage)
		data, err := os.ReadFile(cleanURL)
		if err != nil {
			handler.ServeHTTP(w, r)
			return
		}

		setNoCacheHeaders(w.Header())
		w.Header().Set("Content-Type", "text/html; charset=utf-8")
		w.WriteHeader(http.StatusOK)
		_, err = w.Write(data)
		if err != nil {
			fmt.Printf("Error reading deploy page file: %v\n", err)
		}
	})
}

package main

import (
	"fmt"
	"net/http"
	"os"

	"gitlab.com/gitlab-org/labkit/log"
)

func main() {
	if len(os.Args) == 1 {
		fmt.Fprintf(os.Stderr, "Usage: %s /path/to/test-repo.git\n", os.Args[0])
		os.Exit(1)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, `{"RepoPath":"%s","ArchivePath":"%s"}`, os.Args[1], r.URL.Path)
	})

	log.Fatal(http.ListenAndServe("localhost:8080", nil))
}

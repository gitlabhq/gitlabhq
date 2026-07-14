package main

import (
	"fmt"
	"net/http"
	"os"
)

func main() {
	if len(os.Args) == 1 {
		fmt.Fprintf(os.Stderr, "Usage: %s /path/to/test-repo.git\n", os.Args[0])
		os.Exit(1)
	}

	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, `{"RepoPath":"%s","ArchivePath":"%s"}`, os.Args[1], r.URL.Path)
	})

	if err := http.ListenAndServe("localhost:8080", nil); err != nil {
		fmt.Fprintf(os.Stderr, "fake auth backend server failed: %v", err)
		os.Exit(1)
	}
}

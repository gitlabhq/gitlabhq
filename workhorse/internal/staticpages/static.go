package staticpages

import "net/http"

// Static represents a package for serving static pages and handling errors.
type Static struct {
	DocumentRoot string
	Exclude      []string
}

func setNoCacheHeaders(header http.Header) {
	header.Set("Cache-Control", "no-cache, no-store, max-age=0, must-revalidate")
	header.Set("Pragma", "no-cache")
	header.Set("Expires", "Fri, 01 Jan 1990 00:00:00 GMT")
}

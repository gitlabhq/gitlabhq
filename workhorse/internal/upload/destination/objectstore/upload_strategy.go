package objectstore

import (
	"context"
	"io"
	"net/http"

	"gitlab.com/gitlab-org/labkit/log"
	"gitlab.com/gitlab-org/labkit/mask"
)

type uploadStrategy interface {
	Upload(ctx context.Context, r io.Reader) error
	ETag() string
	Abort()
	Delete()
}

func deleteURL(url string) {
	if url == "" {
		return
	}

	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		log.WithError(err).WithField("object", mask.URL(url)).Warning("Delete failed")
		return
	}
	// TODO: consider adding the context to the outgoing request for better instrumentation

	// here we are not using u.ctx because we must perform cleanup regardless of parent context
	resp, err := httpClient.Do(req)
	if err != nil {
		log.WithError(err).WithField("object", mask.URL(url)).Warning("Delete failed")
		return
	}
	defer func() {
		if err := resp.Body.Close(); err != nil {
			log.WithError(err).WithField("object", mask.URL(url)).Warning("Failed to close response body")
		}
	}()
}

func extractETag(rawETag string) string {
	if rawETag != "" && rawETag[0] == '"' {
		rawETag = rawETag[1 : len(rawETag)-1]
	}

	return rawETag
}

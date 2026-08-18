package objectstore

import (
	"context"
	"io"
	"log/slog"
	"net/http"

	"gitlab.com/gitlab-org/labkit/mask"
	"gitlab.com/gitlab-org/labkit/v2/log"
)

type uploadStrategy interface {
	Upload(ctx context.Context, r io.Reader) error
	ETag() string
	Abort()
	Delete()
	// Strategy returns a stable, low-cardinality name identifying the
	// upload backend (e.g. "gocloud", "presigned_put"), used for logging.
	Strategy() string
}

func deleteURL(url string) {
	if url == "" {
		return
	}

	logger := slog.With(slog.String("object", mask.URL(url)))

	req, err := http.NewRequest("DELETE", url, nil)
	if err != nil {
		logger.Warn("Delete failed", log.Error(err))
		return
	}
	// TODO: consider adding the context to the outgoing request for better instrumentation

	// here we are not using u.ctx because we must perform cleanup regardless of parent context
	resp, err := httpClient.Do(req)
	if err != nil {
		logger.Warn("Delete failed", log.Error(err))
		return
	}

	defer func() {
		if err := resp.Body.Close(); err != nil {
			logger.Warn("Failed to close response body", log.Error(err))
		}
	}()
}

func extractETag(rawETag string) string {
	if rawETag != "" && rawETag[0] == '"' {
		rawETag = rawETag[1 : len(rawETag)-1]
	}

	return rawETag
}

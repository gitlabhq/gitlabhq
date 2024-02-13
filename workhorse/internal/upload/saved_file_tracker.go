package upload

import (
	"context"
	"fmt"
	"io"
	"mime/multipart"
	"net/http"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/secret"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/destination"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/exif"
)

type SavedFileTracker struct {
	Request         *http.Request
	rewrittenFields map[string]string
}

func (s *SavedFileTracker) Track(fieldName string, localPath string) {
	if s.rewrittenFields == nil {
		s.rewrittenFields = make(map[string]string)
	}
	s.rewrittenFields[fieldName] = localPath
}

func (s *SavedFileTracker) Count() int {
	return len(s.rewrittenFields)
}

func (s *SavedFileTracker) ProcessFile(_ context.Context, fieldName string, file *destination.FileHandler, _ *multipart.Writer, _ *config.Config) error {
	if _, ok := s.rewrittenFields[fieldName]; ok {
		return fmt.Errorf("the %v field has already been processed", fieldName)
	}

	s.Track(fieldName, file.LocalPath)
	return nil
}

func (s *SavedFileTracker) ProcessField(_ context.Context, _ string, _ *multipart.Writer) error {
	return nil
}

func (s *SavedFileTracker) Finalize(_ context.Context) error {
	if s.rewrittenFields == nil {
		return nil
	}

	claims := MultipartClaims{RewrittenFields: s.rewrittenFields, RegisteredClaims: secret.DefaultClaims}
	tokenString, err := secret.JWTTokenString(claims)
	if err != nil {
		return fmt.Errorf("savedFileTracker.Finalize: %v", err)
	}

	s.Request.Header.Set(RewrittenFieldsHeader, tokenString)
	return nil
}

func (s *SavedFileTracker) Name() string { return "accelerate" }

func (*SavedFileTracker) TransformContents(ctx context.Context, filename string, r io.Reader) (io.ReadCloser, error) {
	if imageType := exif.FileTypeFromSuffix(filename); imageType != exif.TypeUnknown {
		return handleExifUpload(ctx, r, filename, imageType)
	}

	return io.NopCloser(r), nil
}

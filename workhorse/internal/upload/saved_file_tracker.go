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

// SavedFileTracker tracks saved files.
type SavedFileTracker struct {
	Request         *http.Request
	rewrittenFields map[string]string
}

// Track adds the localPath of the saved file to the tracker with the provided fieldName.
func (s *SavedFileTracker) Track(fieldName string, localPath string) {
	if s.rewrittenFields == nil {
		s.rewrittenFields = make(map[string]string)
	}
	s.rewrittenFields[fieldName] = localPath
}

// Count returns the number of saved file paths tracked by the SavedFileTracker.
func (s *SavedFileTracker) Count() int {
	return len(s.rewrittenFields)
}

// ProcessFile processes the uploaded file and tracks its local path.
// It returns an error if the field name has already been processed.
func (s *SavedFileTracker) ProcessFile(_ context.Context, fieldName string, file *destination.FileHandler, _ *multipart.Writer, _ *config.Config) error {
	if _, ok := s.rewrittenFields[fieldName]; ok {
		return fmt.Errorf("the %v field has already been processed", fieldName)
	}

	s.Track(fieldName, file.LocalPath)
	return nil
}

// ProcessField is a no-op method that implements the FieldProcessor interface.
// It returns nil to indicate successful processing.
func (s *SavedFileTracker) ProcessField(_ context.Context, _ string, _ *multipart.Writer) error {
	return nil
}

// Finalize generates a JWT token containing the rewritten fields and sets it in the request header.
// It returns nil if successful, otherwise it returns an error.
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

// Name returns the name of the saved file tracker.
func (s *SavedFileTracker) Name() string { return "accelerate" }

// TransformContents is a method that implements the destination.FileHandler interface.
// It transforms the contents of the file if it is an image based on its filename and returns a ReadCloser.
// If the file is not an image, it returns the original reader wrapped in a NopCloser.
func (*SavedFileTracker) TransformContents(ctx context.Context, filename string, r io.Reader) (io.ReadCloser, error) {
	if imageType := exif.FileTypeFromSuffix(filename); imageType != exif.TypeUnknown {
		return handleExifUpload(ctx, r, filename, imageType)
	}

	return io.NopCloser(r), nil
}

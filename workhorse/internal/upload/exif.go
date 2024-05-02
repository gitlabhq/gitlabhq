// Package upload provides functionality for handling file uploads and processing image metadata.
package upload

import (
	"context"
	"io"
	"net/http"
	"os"

	"gitlab.com/gitlab-org/labkit/log"
	"golang.org/x/image/tiff"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/upload/exif"
)

func handleExifUpload(ctx context.Context, r io.Reader, filename string, imageType exif.FileType) (io.ReadCloser, error) {
	tmpfile, err := os.CreateTemp("", "exifremove")
	if err != nil {
		return nil, err
	}

	go func() {
		<-ctx.Done()
		_ = tmpfile.Close()
	}()
	if err = os.Remove(tmpfile.Name()); err != nil {
		return nil, err
	}

	_, err = io.Copy(tmpfile, r)
	if err != nil {
		return nil, err
	}

	if _, err = tmpfile.Seek(0, io.SeekStart); err != nil {
		return nil, err
	}

	isValidType := false
	switch imageType {
	case exif.TypeJPEG:
		isValidType = isJPEG(tmpfile)
	case exif.TypeTIFF:
		isValidType = isTIFF(tmpfile)
	}

	if _, err = tmpfile.Seek(0, io.SeekStart); err != nil {
		return nil, err
	}

	if !isValidType {
		log.WithContextFields(ctx, log.Fields{
			"filename":  filename,
			"imageType": imageType,
		}).Info("invalid content type, not running exiftool")

		return tmpfile, nil
	}

	log.WithContextFields(ctx, log.Fields{
		"filename": filename,
	}).Info("running exiftool to remove any metadata")

	cleaner, err := exif.NewCleaner(ctx, tmpfile)
	if err != nil {
		return nil, err
	}

	return cleaner, nil
}

func isTIFF(r io.Reader) bool {
	_, err := tiff.DecodeConfig(r)
	if err == nil {
		return true
	}

	if _, unsupported := err.(tiff.UnsupportedError); unsupported {
		return true
	}

	return false
}

func isJPEG(r io.Reader) bool {
	// Only the first 512 bytes are used to sniff the content type.
	buf, err := io.ReadAll(io.LimitReader(r, 512))
	if err != nil {
		return false
	}

	return http.DetectContentType(buf) == "image/jpeg"
}

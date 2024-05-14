// Package exif provides functionality for extracting EXIF metadata from images.
package exif

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"regexp"

	"gitlab.com/gitlab-org/labkit/log"
)

// ErrRemovingExif is an error returned when there is an issue while removing EXIF metadata from an image.
var ErrRemovingExif = errors.New("error while removing EXIF")

type cleaner struct {
	ctx    context.Context
	cmd    *exec.Cmd
	stdout io.Reader
	stderr bytes.Buffer
	eof    bool
}

// FileType represents the type of an image file.
type FileType int

const (
	// TypeUnknown represents an unknown file type.
	TypeUnknown FileType = iota
	// TypeJPEG represents the JPEG image file type.
	TypeJPEG
	// TypeTIFF represents the TIFF image file type.
	TypeTIFF
)

// NewCleaner creates a new EXIF cleaner instance using the provided context and stdin.
// It processes the input from stdin to remove EXIF data from images.
func NewCleaner(ctx context.Context, stdin io.Reader) (io.ReadCloser, error) {
	c := &cleaner{ctx: ctx}

	if err := c.startProcessing(stdin); err != nil {
		return nil, err
	}

	return c, nil
}

func (c *cleaner) Close() error {
	if c.cmd == nil {
		return nil
	}

	return c.cmd.Wait()
}

func (c *cleaner) Read(p []byte) (int, error) {
	if c.eof {
		return 0, io.EOF
	}

	n, err := c.stdout.Read(p)
	if err == io.EOF {
		if waitErr := c.cmd.Wait(); waitErr != nil {
			log.WithContextFields(c.ctx, log.Fields{
				"command": c.cmd.Args,
				"stderr":  c.stderr.String(),
				"error":   waitErr.Error(),
			}).Print("exiftool command failed")

			return n, ErrRemovingExif
		}

		c.eof = true
	}

	return n, err
}

func (c *cleaner) startProcessing(stdin io.Reader) error {
	var err error

	whitelistedTags := []string{
		"-ResolutionUnit",
		"-XResolution",
		"-YResolution",
		"-YCbCrSubSampling",
		"-YCbCrPositioning",
		"-BitsPerSample",
		"-ImageHeight",
		"-ImageWidth",
		"-ImageSize",
		"-Copyright",
		"-CopyrightNotice",
		"-Orientation",
	}

	args := append([]string{"-all=", "--IPTC:all", "--XMP-iptcExt:all", "-tagsFromFile", "@"}, whitelistedTags...)
	args = append(args, "-")
	c.cmd = exec.CommandContext(c.ctx, "exiftool", args...)

	c.cmd.Stderr = &c.stderr
	c.cmd.Stdin = stdin

	c.stdout, err = c.cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to create stdout pipe: %v", err)
	}

	if err = c.cmd.Start(); err != nil {
		return fmt.Errorf("start %v: %v", c.cmd.Args, err)
	}

	return nil
}

// FileTypeFromSuffix returns the FileType inferred from the filename's suffix.
func FileTypeFromSuffix(filename string) FileType {
	if os.Getenv("SKIP_EXIFTOOL") == "1" {
		return TypeUnknown
	}

	jpegMatch := regexp.MustCompile(`(?i)^[^\n]*\.(jpg|jpeg)$`)
	if jpegMatch.MatchString(filename) {
		return TypeJPEG
	}

	tiffMatch := regexp.MustCompile(`(?i)^[^\n]*\.tiff$`)
	if tiffMatch.MatchString(filename) {
		return TypeTIFF
	}

	return TypeUnknown
}

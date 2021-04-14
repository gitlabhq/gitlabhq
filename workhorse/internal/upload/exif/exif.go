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

var ErrRemovingExif = errors.New("error while removing EXIF")

type cleaner struct {
	ctx    context.Context
	cmd    *exec.Cmd
	stdout io.Reader
	stderr bytes.Buffer
	eof    bool
}

type FileType int

const (
	TypeUnknown FileType = iota
	TypeJPEG
	TypeTIFF
)

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

	whitelisted_tags := []string{
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

	args := append([]string{"-all=", "--IPTC:all", "--XMP-iptcExt:all", "-tagsFromFile", "@"}, whitelisted_tags...)
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

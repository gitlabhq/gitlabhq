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
	"strings"

	"gitlab.com/gitlab-org/labkit/log"
)

// ErrRemovingExif is an error returned when there is an issue while removing EXIF metadata from an image.
var ErrRemovingExif = errors.New("error while removing EXIF")

// Part of the exiftool error emitted when an image carries a malformed
// OtherImageStart offset pointing outside the file (e.g.
// "Error reading OtherImageStart data in IFD0").
const offsetReadErrorSignature = "OtherImageStart"

type cleaner struct {
	ctx            context.Context
	stdin          io.ReadSeeker
	preStrip       *exec.Cmd
	preStripStderr bytes.Buffer
	cmd            *exec.Cmd
	stderr         bytes.Buffer
	stdout         io.Reader
	eof            bool
	waited         bool
	fellBack       bool
	bytesRead      int64
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

// allowlistedTags are the EXIF tags preserved on the normal strip path. They all live in
// IFD0 and are copied back after -all= deletes everything else.
var allowlistedTags = []string{
	"-ResolutionUnit",
	"-XResolution",
	"-YResolution",
	"-YCbCrSubSampling",
	"-YCbCrPositioning",
	"-BitsPerSample",
	"-ImageHeight",
	"-ImageWidth",
	"-ImageSize",
	"-Orientation",
}

// NewCleaner creates a new EXIF cleaner instance using the provided context and stdin.
// The EXIF strip runs as a streaming two-pass exiftool pipeline: an IPTC/XMP prestrip
// feeding a strip that preserves an allowlist of tags. If the prestrip fails on a
// malformed offset, the cleaner rewinds stdin and falls back to a plain full strip.
func NewCleaner(ctx context.Context, stdin io.ReadSeeker) (io.ReadCloser, error) {
	c := &cleaner{ctx: ctx, stdin: stdin}

	if err := c.startProcessing(); err != nil {
		return nil, err
	}

	return c, nil
}

func (c *cleaner) Close() error {
	if c.cmd == nil {
		return nil
	}

	if c.waited {
		return nil
	}

	c.waited = true
	cmdErr := c.cmd.Wait()
	var preStripErr error
	if c.preStrip != nil {
		preStripErr = c.preStrip.Wait()
	}

	if preStripErr != nil {
		return preStripErr
	}
	return cmdErr
}

func (c *cleaner) Read(p []byte) (int, error) {
	if c.eof {
		return 0, io.EOF
	}

	n, err := c.stdout.Read(p)
	c.bytesRead += int64(n)

	if err == io.EOF {
		c.waited = true

		cmdErr := c.cmd.Wait()
		var preStripErr error
		if c.preStrip != nil {
			preStripErr = c.preStrip.Wait()
		}

		if c.shouldFallBack(preStripErr) {
			if fallbackErr := c.startFallback(); fallbackErr != nil {
				c.eof = true
				return n, ErrRemovingExif
			}

			return n, nil
		}

		c.eof = true

		if preStripErr != nil {
			log.WithContextFields(c.ctx, log.Fields{
				"command": c.preStrip.Args,
				"stderr":  c.preStripStderr.String(),
				"error":   preStripErr.Error(),
			}).Print("preStripExif command failed")
			return n, ErrRemovingExif
		}

		if cmdErr != nil {
			log.WithContextFields(c.ctx, log.Fields{
				"command": c.cmd.Args,
				"stderr":  c.stderr.String(),
				"error":   cmdErr.Error(),
			}).Print("exiftool command failed")
			return n, ErrRemovingExif
		}
	}

	return n, err
}

// shouldFallBack reports whether a failed prestrip should trigger the full-strip fallback:
// the failure carries the malformed-offset signature, we have not fallen back already, and
// no output has been delivered to the caller yet, so discarding the failed pipeline's
// output is safe.
func (c *cleaner) shouldFallBack(preStripErr error) bool {
	return preStripErr != nil &&
		strings.Contains(c.preStripStderr.String(), offsetReadErrorSignature) &&
		!c.fellBack &&
		c.bytesRead == 0
}

// startProcessing starts the streaming two-pass pipeline: the prestrip
// ("exiftool -IPTC= -XMP= -") reads stdin and strips the IPTC and XMP groups, which may
// contain unboundedly many tags; the strip reads the prestrip's stdout and strips all
// remaining metadata while copying back the allowlisted tags.
func (c *cleaner) startProcessing() error {
	var err error

	preStrip := exec.CommandContext(c.ctx, "exiftool", "-IPTC=", "-XMP=", "-")
	preStrip.Stderr = &c.preStripStderr
	preStrip.Stdin = c.stdin
	c.preStrip = preStrip

	args := append([]string{"-all=", "-tagsFromFile", "@"}, allowlistedTags...)
	args = append(args, "-")
	//nolint:gosec // G204: Command is hardcoded "exiftool"; args are from the allowlistedTags constant slice
	c.cmd = exec.CommandContext(c.ctx, "exiftool", args...)
	c.cmd.Stderr = &c.stderr
	c.cmd.Stdin, err = preStrip.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to create stdout pipe for removing iptc and xmp: %v", err)
	}

	c.stdout, err = c.cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to create stdout pipe for all exif: %v", err)
	}

	if err = preStrip.Start(); err != nil {
		return fmt.Errorf("start %v: %v", preStrip.Args, err)
	}

	if err = c.cmd.Start(); err != nil {
		return fmt.Errorf("start %v: %v", c.cmd.Args, err)
	}

	return nil
}

// startFallback rewinds stdin and starts a plain "exiftool -all=" full strip reading the
// original bytes directly, replacing the failed pipeline. Orientation is not preserved on
// this path.
func (c *cleaner) startFallback() error {
	log.WithContextFields(c.ctx, log.Fields{
		"stderr": c.preStripStderr.String(),
	}).Warn("exif prestrip failed, falling back to full strip")

	c.fellBack = true
	c.preStrip = nil
	c.stderr.Reset()

	if _, err := c.stdin.Seek(0, io.SeekStart); err != nil {
		return err
	}

	c.cmd = exec.CommandContext(c.ctx, "exiftool", "-all=", "-")
	c.cmd.Stderr = &c.stderr
	c.cmd.Stdin = c.stdin

	stdout, err := c.cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to create stdout pipe for exiftool: %v", err)
	}
	c.stdout = stdout

	if err := c.cmd.Start(); err != nil {
		return fmt.Errorf("start %v: %v", c.cmd.Args, err)
	}

	c.waited = false

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

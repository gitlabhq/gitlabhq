// Package main provides a utility for extracting and displaying files from a ZIP archive.
package main

import (
	"archive/zip"
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"os"

	"gitlab.com/gitlab-org/labkit/mask"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/zipartifacts"
)

const progName = "gitlab-zip-cat"

// Version holds the version of the program, which is set during the build process.
var Version = "unknown"

var printVersion = flag.Bool("version", false, "Print version and exit")

func main() {
	flag.Parse()

	if *printVersion {
		fmt.Printf("%s %s\n", progName, Version)
		os.Exit(0)
	}

	contextErr, statusErr := run()
	if contextErr != nil && statusErr == nil {
		fmt.Fprintln(os.Stderr, statusErr)
		os.Exit(1)
	}

	if contextErr != nil && statusErr != nil {
		fatalError(contextErr, statusErr)
	}
}

func run() (error, error) {
	archivePath := os.Getenv("ARCHIVE_PATH")
	encodedFileName := os.Getenv("ENCODED_FILE_NAME")

	if len(os.Args) != 1 || archivePath == "" || encodedFileName == "" {
		return fmt.Errorf("usage: %s\nEnv: ARCHIVE_PATH=https://path.to/archive.zip or /path/to/archive.zip\nEnv: ENCODED_FILE_NAME=base64-encoded-file-name", progName), nil
	}

	scrubbedArchivePath := mask.URL(archivePath)

	fileName, err := zipartifacts.DecodeFileEntry(encodedFileName)
	if err != nil {
		return fmt.Errorf("decode entry %q", encodedFileName), err
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	archive, err := zipartifacts.OpenArchive(ctx, archivePath)
	if err != nil {
		return errors.New("open archive"), err
	}

	file := findFileInZip(fileName, archive)
	if file == nil {
		return fmt.Errorf("find %q in %q: not found", fileName, scrubbedArchivePath), zipartifacts.ErrorCode[zipartifacts.CodeEntryNotFound]
	}
	// Start decompressing the file
	reader, err := file.Open()
	if err != nil {
		return fmt.Errorf("open %q in %q", fileName, scrubbedArchivePath), err
	}
	defer reader.Close() //nolint:errcheck

	if _, err := fmt.Printf("%d\n", file.UncompressedSize64); err != nil {
		return fmt.Errorf("write file size invalid"), err
	}

	if _, err := io.Copy(os.Stdout, reader); err != nil { //nolint:gosec
		return fmt.Errorf("write %q from %q to stdout", fileName, scrubbedArchivePath), err
	}
	return nil, nil
}

func findFileInZip(fileName string, archive *zip.Reader) *zip.File {
	for _, file := range archive.File {
		if file.Name == fileName {
			return file
		}
	}
	return nil
}

func fatalError(contextErr error, statusErr error) {
	code := zipartifacts.ExitCodeByError(statusErr)

	fmt.Fprintf(os.Stderr, "%s error: %v - %v, code: %d\n", progName, statusErr, contextErr, code)

	if code > 0 {
		os.Exit(code)
	}
	os.Exit(1)
}

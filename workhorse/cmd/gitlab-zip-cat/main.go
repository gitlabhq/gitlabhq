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

var Version = "unknown"

var printVersion = flag.Bool("version", false, "Print version and exit")

func main() {
	flag.Parse()

	version := fmt.Sprintf("%s %s", progName, Version)
	if *printVersion {
		fmt.Println(version)
		os.Exit(0)
	}

	archivePath := os.Getenv("ARCHIVE_PATH")
	encodedFileName := os.Getenv("ENCODED_FILE_NAME")

	if len(os.Args) != 1 || archivePath == "" || encodedFileName == "" {
		fmt.Fprintf(os.Stderr, "Usage: %s\n", progName)
		fmt.Fprintf(os.Stderr, "Env: ARCHIVE_PATH=https://path.to/archive.zip or /path/to/archive.zip\n")
		fmt.Fprintf(os.Stderr, "Env: ENCODED_FILE_NAME=base64-encoded-file-name\n")
		os.Exit(1)
	}

	scrubbedArchivePath := mask.URL(archivePath)

	fileName, err := zipartifacts.DecodeFileEntry(encodedFileName)
	if err != nil {
		fatalError(fmt.Errorf("decode entry %q", encodedFileName), err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	archive, err := zipartifacts.OpenArchive(ctx, archivePath)
	if err != nil {
		fatalError(errors.New("open archive"), err)
	}

	file := findFileInZip(fileName, archive)
	if file == nil {
		fatalError(fmt.Errorf("find %q in %q: not found", fileName, scrubbedArchivePath), zipartifacts.ErrorCode[zipartifacts.CodeEntryNotFound])
	}
	// Start decompressing the file
	reader, err := file.Open()
	if err != nil {
		fatalError(fmt.Errorf("open %q in %q", fileName, scrubbedArchivePath), err)
	}
	defer reader.Close()

	if _, err := fmt.Printf("%d\n", file.UncompressedSize64); err != nil {
		fatalError(fmt.Errorf("write file size invalid"), err)
	}

	if _, err := io.Copy(os.Stdout, reader); err != nil {
		fatalError(fmt.Errorf("write %q from %q to stdout", fileName, scrubbedArchivePath), err)
	}
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
	} else {
		os.Exit(1)
	}
}

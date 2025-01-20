// Package main provides a utility for generating metadata for a ZIP archive.
package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"os"

	"gitlab.com/gitlab-org/gitlab/workhorse/cmd/gitlab-zip-metadata/limit"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/zipartifacts"
)

const progName = "gitlab-zip-metadata"

// Version holds the version of the program, which is set during the build process.
var Version = "unknown"

var printVersion = flag.Bool("version", false, "Print version and exit")
var zipReaderLimitBytes = flag.Int64("zip-reader-limit", config.DefaultMetadataConfig.ZipReaderLimitBytes, "The optional number of bytes to limit the zip reader to")

func main() {
	flag.Parse()

	version := fmt.Sprintf("%s %s", progName, Version)
	if *printVersion {
		fmt.Println(version)
		os.Exit(0)
	}

	if len(flag.Args()) != 1 {
		fmt.Fprintf(os.Stderr, "Usage: %s FILE.ZIP\n", progName)
		os.Exit(1)
	}

	readerFunc := func(reader io.ReaderAt, size int64) io.ReaderAt {
		zipReaderLimit := sizeToLimit(size, *zipReaderLimitBytes)

		return limit.NewLimitedReaderAt(reader, zipReaderLimit, func(read int64) {
			fmt.Fprintf(os.Stderr, "%s: zip archive limit exceeded after reading %d bytes\n", progName, read)

			fatalError(zipartifacts.ErrorCode[zipartifacts.CodeLimitsReached])
		})
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	archive, err := zipartifacts.OpenArchiveWithReaderFunc(ctx, flag.Args()[0], readerFunc)
	if err != nil {
		fatalError(err)
	}

	if err := zipartifacts.GenerateZipMetadata(os.Stdout, archive); err != nil {
		fatalError(err)
	}
}

func fatalError(err error) {
	code := zipartifacts.ExitCodeByError(err)

	fmt.Fprintf(os.Stderr, "%s error: %v, code: %d\n", progName, err, code)

	if code > 0 {
		os.Exit(code)
	}
	os.Exit(1)
}

// sizeToLimit tries to dermine an appropriate limit in bytes for an archive of
// a given size. If the size is less than 1 gigabyte we always limit a reader
// to 100 megabytes, otherwise the limit is 10% of a given size.
func sizeToLimit(size, defaultSize int64) int64 {
	if size <= 1024*config.Megabyte {
		return defaultSize
	}

	return size / 10
}

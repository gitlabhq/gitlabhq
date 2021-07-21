package main

import (
	"context"
	"flag"
	"fmt"
	"io"
	"os"

	"gitlab.com/gitlab-org/gitlab/workhorse/cmd/gitlab-zip-metadata/limit"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/zipartifacts"
)

const progName = "gitlab-zip-metadata"

var Version = "unknown"

var printVersion = flag.Bool("version", false, "Print version and exit")

func main() {
	flag.Parse()

	version := fmt.Sprintf("%s %s", progName, Version)
	if *printVersion {
		fmt.Println(version)
		os.Exit(0)
	}

	if len(os.Args) != 2 {
		fmt.Fprintf(os.Stderr, "Usage: %s FILE.ZIP\n", progName)
		os.Exit(1)
	}

	readerFunc := func(reader io.ReaderAt, size int64) io.ReaderAt {
		readLimit := limit.SizeToLimit(size)

		return limit.NewLimitedReaderAt(reader, readLimit, func(read int64) {
			fmt.Fprintf(os.Stderr, "%s: zip archive limit exceeded after reading %d bytes\n", progName, read)

			fatalError(zipartifacts.ErrorCode[zipartifacts.CodeLimitsReached])
		})
	}

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	archive, err := zipartifacts.OpenArchiveWithReaderFunc(ctx, os.Args[1], readerFunc)
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
	} else {
		os.Exit(1)
	}
}

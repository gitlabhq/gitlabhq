// Package main handles image resizing by reading a PNG/JPG image from stdin and writing a PNG image to stdout.
package main

import (
	"fmt"
	"os"
)

func main() {
	if err := encode(os.Getenv("GL_RESIZE_IMAGE_WIDTH"), os.Stdin, os.Stdout); err != nil {
		fmt.Fprintf(os.Stderr, "%s: fatal: %v\n", os.Args[0], err)
		os.Exit(1)
	}
}

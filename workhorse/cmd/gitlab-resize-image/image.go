package main

import (
	"errors"
	"fmt"
	"image"
	"image/png"
	"io"
	"math"

	"golang.org/x/image/draw"

	glPng "gitlab.com/gitlab-org/gitlab/workhorse/cmd/gitlab-resize-image/png"

	_ "image/jpeg"
)

// Image holds the source image, requested width and functionality to encode
type Image struct {
	Source         image.Image
	RequestedWidth int
}

// NewImage returns a new instance of Image{}
func NewImage(requestedWidth int, r io.Reader) (Image, error) {
	i := Image{RequestedWidth: requestedWidth}

	if requestedWidth <= 0 {
		return i, errors.New("requestedWidth needs to be > 0")
	}

	imgReader, err := glPng.NewReader(r)
	if err != nil {
		return i, fmt.Errorf("construct PNG reader: %w", err)
	}

	src, _, err := image.Decode(imgReader)
	if err != nil {
		return i, fmt.Errorf("decode: %w", err)
	}
	i.Source = src

	return i, nil
}

// Encode writes a resized and scaled image, typically to os.Stdout
func (i Image) Encode(w io.Writer) error {
	ratio := (float64)(i.Source.Bounds().Max.Y) / (float64)(i.Source.Bounds().Max.X)
	height := int(math.Round(float64(i.RequestedWidth) * ratio))
	dst := image.NewRGBA(image.Rect(0, 0, i.RequestedWidth, height))
	draw.ApproxBiLinear.Scale(dst, dst.Rect, i.Source, i.Source.Bounds(), draw.Over, nil)

	return png.Encode(w, dst)
}

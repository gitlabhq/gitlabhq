package main

import (
	"fmt"
	"io"
	"strconv"
)

func encode(widthParam string, r io.Reader, w io.Writer) error {
	requestedWidth, err := strconv.Atoi(widthParam)
	if err != nil {
		return fmt.Errorf("converting widthParam: %w", err)
	}

	i, err := NewImage(requestedWidth, r)
	if err != nil {
		return fmt.Errorf("calling NewImage(): %w", err)
	}

	return i.Encode(w)
}

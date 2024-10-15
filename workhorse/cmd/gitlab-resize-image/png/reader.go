// Package png provides utilities for handling PNG images.
package png

import (
	"bytes"
	"encoding/binary"
	"fmt"
	"io"
	"os"
)

const (
	pngMagicLen = 8
	pngMagic    = "\x89PNG\r\n\x1a\n"
)

// Reader is an io.Reader decorator that skips certain PNG chunks known to cause problems.
// If the image stream is not a PNG, it will yield all bytes unchanged to the underlying
// reader.
// See also https://gitlab.com/gitlab-org/gitlab/-/issues/287614
type Reader struct {
	underlying     io.Reader
	chunk          io.Reader
	bytesRemaining int64
}

// NewReader returns a new Reader that skips problematic PNG chunks.
func NewReader(r io.Reader) (io.Reader, error) {
	magicBytes, err := readMagic(r)
	if err != nil {
		return nil, err
	}

	if string(magicBytes) != pngMagic {
		debug("Not a PNG - read file unchanged")
		return io.MultiReader(bytes.NewReader(magicBytes), r), nil
	}

	return io.MultiReader(bytes.NewReader(magicBytes), &Reader{underlying: r}), nil
}

// Read reads from the PNG stream, skipping specific chunks as needed.
func (r *Reader) Read(p []byte) (int, error) {
	for r.bytesRemaining == 0 {
		const (
			headerLen = 8
			crcLen    = 4
		)
		var header [headerLen]byte
		_, err := io.ReadFull(r.underlying, header[:])
		if err != nil {
			return 0, err
		}

		chunkLen := int64(binary.BigEndian.Uint32(header[:4]))
		if chunkType := string(header[4:]); chunkType == "iCCP" {
			debug("!! iCCP chunk found; skipping")
			if _, err := io.CopyN(io.Discard, r.underlying, chunkLen+crcLen); err != nil {
				return 0, err
			}
			continue
		}

		r.bytesRemaining = headerLen + chunkLen + crcLen
		r.chunk = io.MultiReader(bytes.NewReader(header[:]), io.LimitReader(r.underlying, r.bytesRemaining-headerLen))
	}

	n, err := r.chunk.Read(p)
	r.bytesRemaining -= int64(n)
	return n, err
}

func debug(args ...interface{}) {
	if os.Getenv("DEBUG") == "1" {
		fmt.Fprintln(os.Stderr, args...)
	}
}

// Consume PNG magic and proceed to reading the IHDR chunk.
func readMagic(r io.Reader) ([]byte, error) {
	var magicBytes = make([]byte, pngMagicLen)
	_, err := io.ReadFull(r, magicBytes)
	if err != nil {
		return nil, err
	}

	return magicBytes, nil
}

package destination

import "io"

type hardLimitReader struct {
	r io.Reader
	n int64
}

func (h *hardLimitReader) Read(p []byte) (int, error) {
	nRead, err := h.r.Read(p)
	h.n -= int64(nRead)
	if h.n < 0 {
		err = ErrEntityTooLarge
	}
	return nRead, err
}

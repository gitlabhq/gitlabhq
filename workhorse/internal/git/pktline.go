package git

import (
	"bufio"
	"bytes"
	"fmt"
	"io"
	"strconv"
)

func scanDeepen(body io.Reader) bool {
	scanner := bufio.NewScanner(body)
	scanner.Split(pktLineSplitter)
	for scanner.Scan() {
		if bytes.HasPrefix(scanner.Bytes(), []byte("deepen")) && scanner.Err() == nil {
			return true
		}
	}

	return false
}

func pktLineSplitter(data []byte, atEOF bool) (advance int, token []byte, err error) {
	if len(data) < 4 {
		if atEOF && len(data) > 0 {
			return 0, nil, fmt.Errorf("pktLineSplitter: incomplete length prefix on %q", data)
		}
		return 0, nil, nil // want more data
	}

	if bytes.HasPrefix(data, []byte("0000")) {
		// special case: "0000" terminator packet: return empty token
		return 4, data[:0], nil
	}

	// We have at least 4 bytes available so we can decode the 4-hex digit
	// length prefix of the packet line.
	pktLength64, err := strconv.ParseInt(string(data[:4]), 16, 0)
	if err != nil {
		return 0, nil, fmt.Errorf("pktLineSplitter: decode length: %v", err)
	}

	// Cast is safe because we requested an int-size number from strconv.ParseInt
	pktLength := int(pktLength64)

	if pktLength < 0 {
		return 0, nil, fmt.Errorf("pktLineSplitter: invalid length: %d", pktLength)
	}

	if len(data) < pktLength {
		if atEOF {
			return 0, nil, fmt.Errorf("pktLineSplitter: less than %d bytes in input %q", pktLength, data)
		}
		return 0, nil, nil // want more data
	}

	// return "pkt" token without length prefix
	return pktLength, data[4:pktLength], nil
}

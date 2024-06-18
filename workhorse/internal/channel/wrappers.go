package channel

import (
	"encoding/base64"
	"net"
	"time"

	"github.com/gorilla/websocket"
)

// Wrap wraps the provided connection with the specified subprotocol.
func Wrap(conn Connection, subprotocol string) Connection {
	switch subprotocol {
	case "channel.k8s.io":
		return &kubeWrapper{base64: false, conn: conn}
	case "base64.channel.k8s.io":
		return &kubeWrapper{base64: true, conn: conn}
	case "terminal.gitlab.com":
		return &gitlabWrapper{base64: false, conn: conn}
	case "base64.terminal.gitlab.com":
		return &gitlabWrapper{base64: true, conn: conn}
	}

	return conn
}

type kubeWrapper struct {
	base64 bool
	conn   Connection
}

type gitlabWrapper struct {
	base64 bool
	conn   Connection
}

func (w *gitlabWrapper) ReadMessage() (int, []byte, error) {
	mt, data, err := w.conn.ReadMessage()
	if err != nil {
		return mt, data, err
	}

	if isData(mt) {
		mt = websocket.BinaryMessage
		if w.base64 {
			data, err = decodeBase64(data)
		}
	}

	return mt, data, err
}

func (w *gitlabWrapper) WriteMessage(mt int, data []byte) error {
	if isData(mt) {
		if w.base64 {
			mt = websocket.TextMessage
			data = encodeBase64(data)
		} else {
			mt = websocket.BinaryMessage
		}
	}

	return w.conn.WriteMessage(mt, data)
}

func (w *gitlabWrapper) WriteControl(mt int, data []byte, deadline time.Time) error {
	return w.conn.WriteControl(mt, data, deadline)
}

func (w *gitlabWrapper) UnderlyingConn() net.Conn {
	return w.conn.UnderlyingConn()
}

// Coalesces all wsstreams into a single stream. In practice, we should only
// receive data on stream 1.
func (w *kubeWrapper) ReadMessage() (int, []byte, error) {
	mt, data, err := w.conn.ReadMessage()
	if err != nil {
		return mt, data, err
	}

	if isData(mt) {
		mt = websocket.BinaryMessage

		// Remove the WSStream channel number, decode to raw
		if len(data) > 0 {
			data = data[1:]
			if w.base64 {
				data, err = decodeBase64(data)
			}
		}
	}

	return mt, data, err
}

// Always sends to wsstream 0
func (w *kubeWrapper) WriteMessage(mt int, data []byte) error {
	if isData(mt) {
		if w.base64 {
			mt = websocket.TextMessage
			data = append([]byte{'0'}, encodeBase64(data)...)
		} else {
			mt = websocket.BinaryMessage
			data = append([]byte{0}, data...)
		}
	}

	return w.conn.WriteMessage(mt, data)
}

func (w *kubeWrapper) WriteControl(mt int, data []byte, deadline time.Time) error {
	return w.conn.WriteControl(mt, data, deadline)
}

func (w *kubeWrapper) UnderlyingConn() net.Conn {
	return w.conn.UnderlyingConn()
}

func isData(mt int) bool {
	return mt == websocket.BinaryMessage || mt == websocket.TextMessage
}

func encodeBase64(data []byte) []byte {
	buf := make([]byte, base64.StdEncoding.EncodedLen(len(data)))
	base64.StdEncoding.Encode(buf, data)

	return buf
}

func decodeBase64(data []byte) ([]byte, error) {
	buf := make([]byte, base64.StdEncoding.DecodedLen(len(data)))
	n, err := base64.StdEncoding.Decode(buf, data)
	return buf[:n], err
}

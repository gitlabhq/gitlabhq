package channel

import (
	"bytes"
	"errors"
	"net"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

type testcase struct {
	input    *fakeConn
	expected *fakeConn
}

type fakeConn struct {
	// WebSocket message type
	mt   int
	data []byte
	err  error
}

func (f *fakeConn) ReadMessage() (int, []byte, error) {
	return f.mt, f.data, f.err
}

func (f *fakeConn) WriteMessage(mt int, data []byte) error {
	f.mt = mt
	f.data = data
	return f.err
}

func (f *fakeConn) WriteControl(mt int, data []byte, _ time.Time) error {
	f.mt = mt
	f.data = data
	return f.err
}

func (f *fakeConn) UnderlyingConn() net.Conn {
	return nil
}

func fake(mt int, data []byte, err error) *fakeConn {
	return &fakeConn{mt: mt, data: data, err: err}
}

var (
	msg           = []byte("foo bar")
	msgBase64     = []byte("Zm9vIGJhcg==")
	kubeMsg       = append([]byte{0}, msg...)
	kubeMsgBase64 = append([]byte{'0'}, msgBase64...)

	errFake = errors.New("fake error")

	text   = websocket.TextMessage
	binary = websocket.BinaryMessage
	other  = 999

	fakeOther = fake(other, []byte("foo"), nil)
)

func requireEqualConn(t *testing.T, expected, actual *fakeConn, msg string, args ...interface{}) {
	if expected.mt != actual.mt {
		t.Logf("messageType expected to be %v but was %v", expected.mt, actual.mt)
		t.Fatalf(msg, args...)
	}

	if !bytes.Equal(expected.data, actual.data) {
		t.Logf("data expected to be %q but was %q: ", expected.data, actual.data)
		t.Fatalf(msg, args...)
	}

	if expected.err != actual.err {
		t.Logf("error expected to be %v but was %v", expected.err, actual.err)
		t.Fatalf(msg, args...)
	}
}

func TestReadMessage(t *testing.T) {
	testCases := map[string][]testcase{
		"channel.k8s.io": {
			{fake(binary, kubeMsg, errFake), fake(binary, kubeMsg, errFake)},
			{fake(binary, kubeMsg, nil), fake(binary, msg, nil)},
			{fake(text, kubeMsg, nil), fake(binary, msg, nil)},
			{fakeOther, fakeOther},
		},
		"base64.channel.k8s.io": {
			{fake(text, kubeMsgBase64, errFake), fake(text, kubeMsgBase64, errFake)},
			{fake(text, kubeMsgBase64, nil), fake(binary, msg, nil)},
			{fake(binary, kubeMsgBase64, nil), fake(binary, msg, nil)},
			{fakeOther, fakeOther},
		},
		"terminal.gitlab.com": {
			{fake(binary, msg, errFake), fake(binary, msg, errFake)},
			{fake(binary, msg, nil), fake(binary, msg, nil)},
			{fake(text, msg, nil), fake(binary, msg, nil)},
			{fakeOther, fakeOther},
		},
		"base64.terminal.gitlab.com": {
			{fake(text, msgBase64, errFake), fake(text, msgBase64, errFake)},
			{fake(text, msgBase64, nil), fake(binary, msg, nil)},
			{fake(binary, msgBase64, nil), fake(binary, msg, nil)},
			{fakeOther, fakeOther},
		},
	}

	for subprotocol, cases := range testCases {
		for i, tc := range cases {
			conn := Wrap(tc.input, subprotocol)
			mt, data, err := conn.ReadMessage()
			actual := fake(mt, data, err)
			requireEqualConn(t, tc.expected, actual, "%s test case %v", subprotocol, i)
		}
	}
}

func TestWriteMessage(t *testing.T) {
	testCases := map[string][]testcase{
		"channel.k8s.io": {
			{fake(binary, msg, errFake), fake(binary, kubeMsg, errFake)},
			{fake(binary, msg, nil), fake(binary, kubeMsg, nil)},
			{fake(text, msg, nil), fake(binary, kubeMsg, nil)},
			{fakeOther, fakeOther},
		},
		"base64.channel.k8s.io": {
			{fake(binary, msg, errFake), fake(text, kubeMsgBase64, errFake)},
			{fake(binary, msg, nil), fake(text, kubeMsgBase64, nil)},
			{fake(text, msg, nil), fake(text, kubeMsgBase64, nil)},
			{fakeOther, fakeOther},
		},
		"terminal.gitlab.com": {
			{fake(binary, msg, errFake), fake(binary, msg, errFake)},
			{fake(binary, msg, nil), fake(binary, msg, nil)},
			{fake(text, msg, nil), fake(binary, msg, nil)},
			{fakeOther, fakeOther},
		},
		"base64.terminal.gitlab.com": {
			{fake(binary, msg, errFake), fake(text, msgBase64, errFake)},
			{fake(binary, msg, nil), fake(text, msgBase64, nil)},
			{fake(text, msg, nil), fake(text, msgBase64, nil)},
			{fakeOther, fakeOther},
		},
	}

	for subprotocol, cases := range testCases {
		for i, tc := range cases {
			actual := fake(0, nil, tc.input.err)
			conn := Wrap(actual, subprotocol)
			actual.err = conn.WriteMessage(tc.input.mt, tc.input.data)
			requireEqualConn(t, tc.expected, actual, "%s test case %v", subprotocol, i)
		}
	}
}

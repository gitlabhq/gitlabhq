package main

import (
	"bytes"
	"encoding/pem"
	"fmt"
	"net"
	"net/http"
	"net/http/httptest"
	"net/url"
	"path"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/require"
	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
)

var (
	envTerminalPath     = fmt.Sprintf("%s/-/environments/1/terminal.ws", testProject)
	jobTerminalPath     = fmt.Sprintf("%s/-/jobs/1/terminal.ws", testProject)
	servicesProxyWSPath = fmt.Sprintf("%s/-/jobs/1/proxy.ws", testProject)
)

type connWithReq struct {
	conn *websocket.Conn
	req  *http.Request
}

func TestChannelHappyPath(t *testing.T) {
	tests := []struct {
		name        string
		channelPath string
	}{
		{"environments", envTerminalPath},
		{"jobs", jobTerminalPath},
		{"services", servicesProxyWSPath},
	}
	for _, test := range tests {
		t.Run(test.name, func(t *testing.T) {
			serverConns, clientURL, close := wireupChannel(t, test.channelPath, nil, "channel.k8s.io")
			defer close()

			client, _, err := dialWebsocket(clientURL, nil, "terminal.gitlab.com")
			require.NoError(t, err)

			server := (<-serverConns).conn
			defer server.Close()

			message := "test message"

			// channel.k8s.io: server writes to channel 1, STDOUT
			require.NoError(t, say(server, "\x01"+message))
			requireReadMessage(t, client, websocket.BinaryMessage, message)

			require.NoError(t, say(client, message))

			// channel.k8s.io: client writes get put on channel 0, STDIN
			requireReadMessage(t, server, websocket.BinaryMessage, "\x00"+message)

			// Closing the client should send an EOT signal to the server's STDIN
			client.Close()
			requireReadMessage(t, server, websocket.BinaryMessage, "\x00\x04")
		})
	}
}

func TestChannelBadTLS(t *testing.T) {
	_, clientURL, close := wireupChannel(t, envTerminalPath, badCA, "channel.k8s.io")
	defer close()

	_, _, err := dialWebsocket(clientURL, nil, "terminal.gitlab.com")
	require.Equal(t, websocket.ErrBadHandshake, err, "unexpected error %v", err)
}

func TestChannelSessionTimeout(t *testing.T) {
	serverConns, clientURL, close := wireupChannel(t, envTerminalPath, timeout, "channel.k8s.io")
	defer close()

	client, _, err := dialWebsocket(clientURL, nil, "terminal.gitlab.com")
	require.NoError(t, err)

	sc := <-serverConns
	defer sc.conn.Close()

	client.SetReadDeadline(time.Now().Add(time.Duration(2) * time.Second))
	_, _, err = client.ReadMessage()

	require.True(t, websocket.IsCloseError(err, websocket.CloseAbnormalClosure), "Client connection was not closed, got %v", err)
}

func TestChannelProxyForwardsHeadersFromUpstream(t *testing.T) {
	hdr := make(http.Header)
	hdr.Set("Random-Header", "Value")
	serverConns, clientURL, close := wireupChannel(t, envTerminalPath, setHeader(hdr), "channel.k8s.io")
	defer close()

	client, _, err := dialWebsocket(clientURL, nil, "terminal.gitlab.com")
	require.NoError(t, err)
	defer client.Close()

	sc := <-serverConns
	defer sc.conn.Close()
	require.Equal(t, "Value", sc.req.Header.Get("Random-Header"), "Header specified by upstream not sent to remote")
}

func TestChannelProxyForwardsXForwardedForFromClient(t *testing.T) {
	serverConns, clientURL, close := wireupChannel(t, envTerminalPath, nil, "channel.k8s.io")
	defer close()

	hdr := make(http.Header)
	hdr.Set("X-Forwarded-For", "127.0.0.2")
	client, _, err := dialWebsocket(clientURL, hdr, "terminal.gitlab.com")
	require.NoError(t, err)
	defer client.Close()

	clientIP, _, err := net.SplitHostPort(client.LocalAddr().String())
	require.NoError(t, err)

	sc := <-serverConns
	defer sc.conn.Close()

	require.Equal(t, "127.0.0.2, "+clientIP, sc.req.Header.Get("X-Forwarded-For"), "X-Forwarded-For from client not sent to remote")
}

func wireupChannel(t *testing.T, channelPath string, modifier func(*api.Response), subprotocols ...string) (chan connWithReq, string, func()) {
	serverConns, remote := startWebsocketServer(subprotocols...)
	authResponse := channelOkBody(remote, nil, subprotocols...)
	if modifier != nil {
		modifier(authResponse)
	}
	upstream := testAuthServer(t, nil, nil, 200, authResponse)
	workhorse := startWorkhorseServer(upstream.URL)

	return serverConns, websocketURL(workhorse.URL, channelPath), func() {
		workhorse.Close()
		upstream.Close()
		remote.Close()
	}
}

func startWebsocketServer(subprotocols ...string) (chan connWithReq, *httptest.Server) {
	upgrader := &websocket.Upgrader{Subprotocols: subprotocols}

	connCh := make(chan connWithReq, 1)
	server := httptest.NewTLSServer(webSocketHandler(upgrader, connCh))

	return connCh, server
}

func webSocketHandler(upgrader *websocket.Upgrader, connCh chan connWithReq) http.HandlerFunc {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		logEntry := log.WithFields(log.Fields{
			"method":  r.Method,
			"url":     r.URL,
			"headers": r.Header,
		})

		logEntry.Info("WEBSOCKET")
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			logEntry.WithError(err).Error("WEBSOCKET Upgrade failed")
			return
		}
		connCh <- connWithReq{conn, r}
		// The connection has been hijacked so it's OK to end here
	})
}

func channelOkBody(remote *httptest.Server, header http.Header, subprotocols ...string) *api.Response {
	out := &api.Response{
		Channel: &api.ChannelSettings{
			Url:            websocketURL(remote.URL),
			Header:         header,
			Subprotocols:   subprotocols,
			MaxSessionTime: 0,
		},
	}

	if len(remote.TLS.Certificates) > 0 {
		data := bytes.NewBuffer(nil)
		pem.Encode(data, &pem.Block{Type: "CERTIFICATE", Bytes: remote.TLS.Certificates[0].Certificate[0]})
		out.Channel.CAPem = data.String()
	}

	return out
}

func badCA(authResponse *api.Response) {
	authResponse.Channel.CAPem = "Bad CA"
}

func timeout(authResponse *api.Response) {
	authResponse.Channel.MaxSessionTime = 1
}

func setHeader(hdr http.Header) func(*api.Response) {
	return func(authResponse *api.Response) {
		authResponse.Channel.Header = hdr
	}
}

func dialWebsocket(url string, header http.Header, subprotocols ...string) (*websocket.Conn, *http.Response, error) {
	dialer := &websocket.Dialer{
		Subprotocols: subprotocols,
	}

	return dialer.Dial(url, header)
}

func websocketURL(httpURL string, suffix ...string) string {
	url, err := url.Parse(httpURL)
	if err != nil {
		panic(err)
	}

	switch url.Scheme {
	case "http":
		url.Scheme = "ws"
	case "https":
		url.Scheme = "wss"
	default:
		panic("Unknown scheme: " + url.Scheme)
	}

	url.Path = path.Join(url.Path, strings.Join(suffix, "/"))

	return url.String()
}

func say(conn *websocket.Conn, message string) error {
	return conn.WriteMessage(websocket.TextMessage, []byte(message))
}

func requireReadMessage(t *testing.T, conn *websocket.Conn, expectedMessageType int, expectedData string) {
	messageType, data, err := conn.ReadMessage()
	require.NoError(t, err)

	require.Equal(t, expectedMessageType, messageType, "message type")
	require.Equal(t, expectedData, string(data), "message data")
}

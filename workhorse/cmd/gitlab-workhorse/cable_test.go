package main

import (
	"net/http"
	"net/http/httptest"
	"net/url"
	"regexp"
	"testing"

	"github.com/gorilla/websocket"
	"github.com/stretchr/testify/require"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/config"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/testhelper"
)

const cablePath = "/-/cable"

func TestSingleBackend(t *testing.T) {
	cableServerConns, cableBackendServer := startCableServer(t)

	config := newUpstreamWithCableConfig(cableBackendServer.URL, "")
	workhorse := startWorkhorseServerWithConfig(t, config)

	cableURL := websocketURL(workhorse.URL, cablePath)

	client, http, err := dialWebsocket(cableURL, nil)
	defer http.Body.Close()
	require.NoError(t, err)
	defer client.Close()

	server := (<-cableServerConns).conn
	defer server.Close()

	require.NoError(t, say(client, "hello"))
	requireReadMessage(t, server, websocket.TextMessage, "hello")

	require.NoError(t, say(server, "world"))
	requireReadMessage(t, client, websocket.TextMessage, "world")
}

func TestSeparateCableBackend(t *testing.T) {
	authBackendServer := testhelper.TestServerWithHandler(t, regexp.MustCompile(`.`), http.HandlerFunc(http.NotFoundHandler().ServeHTTP))

	cableServerConns, cableBackendServer := startCableServer(t)

	config := newUpstreamWithCableConfig(authBackendServer.URL, cableBackendServer.URL)
	workhorse := startWorkhorseServerWithConfig(t, config)

	cableURL := websocketURL(workhorse.URL, cablePath)

	client, http, err := dialWebsocket(cableURL, nil)
	defer http.Body.Close()
	require.NoError(t, err)
	defer client.Close()

	server := (<-cableServerConns).conn
	defer server.Close()

	require.NoError(t, say(client, "hello"))
	requireReadMessage(t, server, websocket.TextMessage, "hello")

	require.NoError(t, say(server, "world"))
	requireReadMessage(t, client, websocket.TextMessage, "world")
}

func startCableServer(t *testing.T) (chan connWithReq, *httptest.Server) {
	upgrader := &websocket.Upgrader{}

	connCh := make(chan connWithReq, 1)
	server := testhelper.TestServerWithHandler(t, regexp.MustCompile(cablePath), webSocketHandler(upgrader, connCh))

	return connCh, server
}

func newUpstreamWithCableConfig(authBackend string, cableBackend string) *config.Config {
	var cableBackendURL *url.URL

	if cableBackend != "" {
		cableBackendURL = helper.URLMustParse(cableBackend)
	}

	return &config.Config{
		Version:      "123",
		DocumentRoot: testDocumentRoot,
		Backend:      helper.URLMustParse(authBackend),
		CableBackend: cableBackendURL,
	}
}

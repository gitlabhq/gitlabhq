# Websocket channel support

In some cases, GitLab can provide in-browser terminal access to an
environment (which is a running server or container, onto which a
project has been deployed), or even access to services running in CI
through a WebSocket. Workhorse manages the WebSocket upgrade and
long-lived connection to the websocket connection, which frees
up GitLab to process other requests.

This document outlines the architecture of these connections.

## Introduction to WebSockets

A websocket is an "upgraded" HTTP/1.1 request. Their purpose is to
permit bidirectional communication between a client and a server.
**Websockets are not HTTP**. Clients can send messages (known as
frames) to the server at any time, and vice-versa. Client messages
are not necessarily requests, and server messages are not necessarily
responses. WebSocket URLs have schemes like `ws://` (unencrypted) or
`wss://` (TLS-secured).

When requesting an upgrade to WebSocket, the browser sends a HTTP/1.1
request that looks like this:

```
GET /path.ws HTTP/1.1
Connection: upgrade
Upgrade: websocket
Sec-WebSocket-Protocol: terminal.gitlab.com
# More headers, including security measures
```

At this point, the connection is still HTTP, so this is a request and
the server can send a normal HTTP response, including `404 Not Found`,
`500 Internal Server Error`, etc.

If the server decides to permit the upgrade, it will send a HTTP
`101 Switching Protocols` response. From this point, the connection
is no longer HTTP. It is a WebSocket and frames, not HTTP requests,
will flow over it. The connection will persist until the client or
server closes the connection.

In addition to the subprotocol, individual websocket frames may
also specify a message type - examples include `BinaryMessage`,
`TextMessage`, `Ping`, `Pong` or `Close`. Only binary frames can
contain arbitrary data - other frames are expected to be valid
UTF-8 strings, in addition to any subprotocol expectations.

## Browser to Workhorse

Using the terminal as an example, GitLab serves a JavaScript terminal
emulator to the browser on a URL like
`https://gitlab.com/group/project/-/environments/1/terminal`.
This opens a websocket connection to, e.g.,
`wss://gitlab.com/group/project/-/environments/1/terminal.ws`,
This endpoint doesn't exist in GitLab - only in Workhorse.

When receiving the connection, Workhorse first checks that the
client is authorized to access the requested terminal. It does
this by performing a "preauthentication" request to GitLab.

If the client has the appropriate permissions and the terminal
exists, GitLab responds with a successful response that includes
details of the terminal that the client should be connected to.
Otherwise, it returns an appropriate HTTP error response.

Errors are passed back to the client as HTTP responses, but if
GitLab returns valid terminal details to Workhorse, it will
connect to the specified terminal, upgrade the browser to a
WebSocket, and proxy between the two connections for as long
as the browser's credentials are valid. Workhorse will also
send regular `PingMessage` control frames to the browser, to
keep intervening proxies from terminating the connection
while the browser is present.

The browser must request an upgrade with a specific subprotocol:

### `terminal.gitlab.com`

This subprotocol considers `TextMessage` frames to be invalid.
Control frames, such as `PingMessage` or `CloseMessage`, have
their usual meanings.

`BinaryMessage` frames sent from the browser to the server are
arbitrary text input.

`BinaryMessage` frames sent from the server to the browser are
arbitrary text output.

These frames are expected to contain ANSI text control codes
and may be in any encoding.

### `base64.terminal.gitlab.com`

This subprotocol considers `BinaryMessage` frames to be invalid.
Control frames, such as `PingMessage` or `CloseMessage`, have
their usual meanings.

`TextMessage` frames sent from the browser to the server are
base64-encoded arbitrary text input (so the server must
base64-decode them before inputting them).

`TextMessage` frames sent from the server to the browser are
base64-encoded arbitrary text output (so the browser must
base64-decode them before outputting them).

In their base64-encoded form, these frames are expected to
contain ANSI terminal control codes, and may be in any encoding.

## Workhorse to GitLab

Using again the terminal as an example, before upgrading the browser,
Workhorse sends a normal HTTP request to GitLab on a URL like
`https://gitlab.com/group/project/environments/1/terminal.ws/authorize`.
This returns a JSON response containing details of where the
terminal can be found, and how to connect it. In particular,
the following details are returned in case of success:

* WebSocket URL to **connect** to, e.g.: `wss://example.com/terminals/1.ws?tty=1`
* WebSocket subprotocols to support, e.g.: `["channel.k8s.io"]`
* Headers to send, e.g.: `Authorization: Token xxyyz..`
* Certificate authority to verify `wss` connections with (optional)

Workhorse periodically re-checks this endpoint, and if it gets an
error response, or the details of the terminal change, it will
terminate the websocket session.

## Workhorse to the WebSocket server

In GitLab, environments or CI jobs may have a deployment service (e.g.,
`KubernetesService`) associated with them. This service knows
where the terminals or the service for an environment may be found, and these
details are returned to Workhorse by GitLab.

These URLs are *also* WebSocket URLs, and GitLab tells Workhorse
which subprotocols to speak over the connection, along with any
authentication details required by the remote end.

Before upgrading the browser's connection to a websocket,
Workhorse opens a HTTP client connection, according to the
details given to it by Workhorse, and attempts to upgrade
that connection to a websocket. If it fails, an error
response is sent to the browser; otherwise, the browser is
also upgraded.

Workhorse now has two websocket connections, albeit with
differing subprotocols. It decodes incoming frames from the
browser, re-encodes them to the the channel's subprotocol, and
sends them to the channel. Similarly, it decodes incoming
frames from the channel, re-encodes them to the browser's
subprotocol, and sends them to the browser.

When either connection closes or enters an error state,
Workhorse detects the error and closes the other connection,
terminating the channel session. If the browser is the
connection that has disconnected, Workhorse will send an ANSI
`End of Transmission` control code (the `0x04` byte) to the
channel, encoded according to the appropriate subprotocol.
Workhorse will automatically reply to any websocket ping frame
sent by the channel, to avoid being disconnected.

Currently, Workhorse only supports the following subprotocols.
Supporting new deployment services will require new subprotocols
to be supported:

### `channel.k8s.io`

Used by Kubernetes, this subprotocol defines a simple multiplexed
channel.

Control frames have their usual meanings. `TextMessage` frames are
invalid. `BinaryMessage` frames represent I/O to a specific file
descriptor.

The first byte of each `BinaryMessage` frame represents the file
descriptor (fd) number, as a `uint8` (so the value `0x00` corresponds
to fd 0, `STDIN`, while `0x01` corresponds to fd 1, `STDOUT`).

The remaining bytes represent arbitrary data. For frames received
from the server, they are bytes that have been received from that
fd. For frames sent to the server, they are bytes that should be
written to that fd.

### `base64.channel.k8s.io`

Also used by Kubernetes, this subprotocol defines a similar multiplexed
channel to `channel.k8s.io`. The main differences are:

* `TextMessage` frames are valid, rather than `BinaryMessage` frames.
* The first byte of each `TextMessage` frame represents the file
  descriptor as a numeric UTF-8 character, so the character `U+0030`,
  or "0", is fd 0, STDIN).
* The remaining bytes represent base64-encoded arbitrary data.


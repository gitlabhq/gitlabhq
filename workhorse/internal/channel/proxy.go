package channel

import (
	"fmt"
	"net"
	"time"

	"github.com/gorilla/websocket"
)

// ANSI "end of channel" code
var eot = []byte{0x04}

// An abstraction of gorilla's *websocket.Conn
type Connection interface {
	UnderlyingConn() net.Conn
	ReadMessage() (int, []byte, error)
	WriteMessage(int, []byte) error
	WriteControl(int, []byte, time.Time) error
}

type Proxy struct {
	StopCh chan error
}

// stoppers is the number of goroutines that may attempt to call Stop()
func NewProxy(stoppers int) *Proxy {
	return &Proxy{
		StopCh: make(chan error, stoppers+2), // each proxy() call is a stopper
	}
}

func (p *Proxy) Serve(upstream, downstream Connection, upstreamAddr, downstreamAddr string) error {
	// This signals the upstream channel to kill the exec'd process
	defer upstream.WriteMessage(websocket.BinaryMessage, eot)

	go p.proxy(upstream, downstream, upstreamAddr, downstreamAddr)
	go p.proxy(downstream, upstream, downstreamAddr, upstreamAddr)

	return <-p.StopCh
}

func (p *Proxy) proxy(to, from Connection, toAddr, fromAddr string) {
	for {
		messageType, data, err := from.ReadMessage()
		if err != nil {
			p.StopCh <- fmt.Errorf("reading from %s: %s", fromAddr, err)
			break
		}

		if err := to.WriteMessage(messageType, data); err != nil {
			p.StopCh <- fmt.Errorf("writing to %s: %s", toAddr, err)
			break
		}
	}
}

package channel

import (
	"fmt"
	"net/http"
	"time"

	"github.com/gorilla/websocket"

	"gitlab.com/gitlab-org/labkit/log"

	"gitlab.com/gitlab-org/gitlab/workhorse/internal/api"
	"gitlab.com/gitlab-org/gitlab/workhorse/internal/helper"
)

var (
	// See doc/channel.md for documentation of this subprotocol
	subprotocols             = []string{"terminal.gitlab.com", "base64.terminal.gitlab.com"}
	upgrader                 = &websocket.Upgrader{Subprotocols: subprotocols}
	ReauthenticationInterval = 5 * time.Minute
	BrowserPingInterval      = 30 * time.Second
)

func Handler(myAPI *api.API) http.Handler {
	return myAPI.PreAuthorizeHandler(func(w http.ResponseWriter, r *http.Request, a *api.Response) {
		if err := a.Channel.Validate(); err != nil {
			helper.Fail500(w, r, err)
			return
		}

		proxy := NewProxy(2) // two stoppers: auth checker, max time
		checker := NewAuthChecker(
			authCheckFunc(myAPI, r, "authorize"),
			a.Channel,
			proxy.StopCh,
		)
		defer checker.Close()
		go checker.Loop(ReauthenticationInterval)
		go closeAfterMaxTime(proxy, a.Channel.MaxSessionTime)

		ProxyChannel(w, r, a.Channel, proxy)
	}, "authorize")
}

func ProxyChannel(w http.ResponseWriter, r *http.Request, settings *api.ChannelSettings, proxy *Proxy) {
	server, err := connectToServer(settings, r)
	if err != nil {
		helper.Fail500(w, r, err)
		log.ContextLogger(r.Context()).WithError(err).Print("Channel: connecting to server failed")
		return
	}
	defer server.UnderlyingConn().Close()
	serverAddr := server.UnderlyingConn().RemoteAddr().String()

	client, err := upgradeClient(w, r)
	if err != nil {
		log.ContextLogger(r.Context()).WithError(err).Print("Channel: upgrading client to websocket failed")
		return
	}

	// Regularly send ping messages to the browser to keep the websocket from
	// being timed out by intervening proxies.
	go pingLoop(client)

	defer client.UnderlyingConn().Close()
	clientAddr := getClientAddr(r) // We can't know the port with confidence

	logEntry := log.WithContextFields(r.Context(), log.Fields{
		"clientAddr": clientAddr,
		"serverAddr": serverAddr,
	})

	logEntry.Print("Channel: started proxying")

	defer logEntry.Print("Channel: finished proxying")

	if err := proxy.Serve(server, client, serverAddr, clientAddr); err != nil {
		logEntry.WithError(err).Print("Channel: error proxying")
	}
}

// In the future, we might want to look at X-Client-Ip or X-Forwarded-For
func getClientAddr(r *http.Request) string {
	return r.RemoteAddr
}

func upgradeClient(w http.ResponseWriter, r *http.Request) (Connection, error) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		return nil, err
	}

	return Wrap(conn, conn.Subprotocol()), nil
}

func pingLoop(conn Connection) {
	for {
		time.Sleep(BrowserPingInterval)
		deadline := time.Now().Add(5 * time.Second)
		if err := conn.WriteControl(websocket.PingMessage, nil, deadline); err != nil {
			// Either the connection was already closed so no further pings are
			// needed, or this connection is now dead and no further pings can
			// be sent.
			break
		}
	}
}

func connectToServer(settings *api.ChannelSettings, r *http.Request) (Connection, error) {
	settings = settings.Clone()

	helper.SetForwardedFor(&settings.Header, r)

	conn, _, err := settings.Dial()
	if err != nil {
		return nil, err
	}

	return Wrap(conn, conn.Subprotocol()), nil
}

func closeAfterMaxTime(proxy *Proxy, maxSessionTime int) {
	if maxSessionTime == 0 {
		return
	}

	<-time.After(time.Duration(maxSessionTime) * time.Second)
	proxy.StopCh <- fmt.Errorf(
		"connection closed: session time greater than maximum time allowed - %v seconds",
		maxSessionTime,
	)
}

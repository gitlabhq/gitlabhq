package api

import (
	"net/http"
	"testing"
)

func channel(url string, subprotocols ...string) *ChannelSettings {
	return &ChannelSettings{
		Url:            url,
		Subprotocols:   subprotocols,
		MaxSessionTime: 0,
	}
}

func ca(channel *ChannelSettings) *ChannelSettings {
	channel = channel.Clone()
	channel.CAPem = "Valid CA data"

	return channel
}

func timeout(channel *ChannelSettings) *ChannelSettings {
	channel = channel.Clone()
	channel.MaxSessionTime = 600

	return channel
}

func header(channel *ChannelSettings, values ...string) *ChannelSettings {
	if len(values) == 0 {
		values = []string{"Dummy Value"}
	}

	channel = channel.Clone()
	channel.Header = http.Header{
		"Header": values,
	}

	return channel
}

func TestClone(t *testing.T) {
	a := ca(header(channel("ws:", "", "")))
	b := a.Clone()

	if a == b {
		t.Fatalf("Address of cloned channel didn't change")
	}

	if &a.Subprotocols == &b.Subprotocols {
		t.Fatalf("Address of cloned subprotocols didn't change")
	}

	if &a.Header == &b.Header {
		t.Fatalf("Address of cloned header didn't change")
	}
}

func TestValidate(t *testing.T) {
	for i, tc := range []struct {
		channel *ChannelSettings
		valid   bool
		msg     string
	}{
		{nil, false, "nil channel"},
		{channel("", ""), false, "empty URL"},
		{channel("ws:"), false, "empty subprotocols"},
		{channel("ws:", "foo"), true, "any subprotocol"},
		{channel("ws:", "foo", "bar"), true, "multiple subprotocols"},
		{channel("ws:", ""), true, "websocket URL"},
		{channel("wss:", ""), true, "secure websocket URL"},
		{channel("http:", ""), false, "HTTP URL"},
		{channel("https:", ""), false, " HTTPS URL"},
		{ca(channel("ws:", "")), true, "any CA pem"},
		{header(channel("ws:", "")), true, "any headers"},
		{ca(header(channel("ws:", ""))), true, "PEM and headers"},
	} {
		if err := tc.channel.Validate(); (err != nil) == tc.valid {
			t.Fatalf("test case %d: "+tc.msg+": valid=%v: %s: %+v", i, tc.valid, err, tc.channel)
		}
	}
}

func TestDialer(t *testing.T) {
	channel := channel("ws:", "foo")
	dialer := channel.Dialer()

	if len(dialer.Subprotocols) != len(channel.Subprotocols) {
		t.Fatalf("Subprotocols don't match: %+v vs. %+v", channel.Subprotocols, dialer.Subprotocols)
	}

	for i, subprotocol := range channel.Subprotocols {
		if dialer.Subprotocols[i] != subprotocol {
			t.Fatalf("Subprotocols don't match: %+v vs. %+v", channel.Subprotocols, dialer.Subprotocols)
		}
	}

	if dialer.TLSClientConfig != nil {
		t.Fatalf("Unexpected TLSClientConfig: %+v", dialer)
	}

	channel = ca(channel)
	dialer = channel.Dialer()

	if dialer.TLSClientConfig == nil || dialer.TLSClientConfig.RootCAs == nil {
		t.Fatalf("Custom CA certificates not recognised!")
	}
}

func TestIsEqual(t *testing.T) {
	chann := channel("ws:", "foo")

	chann_header2 := header(chann, "extra")
	chann_header3 := header(chann)
	chann_header3.Header.Add("Extra", "extra")

	chann_ca2 := ca(chann)
	chann_ca2.CAPem = "other value"

	for i, tc := range []struct {
		channelA *ChannelSettings
		channelB *ChannelSettings
		expected bool
	}{
		{nil, nil, true},
		{chann, nil, false},
		{nil, chann, false},
		{chann, chann, true},
		{chann.Clone(), chann.Clone(), true},
		{chann, channel("foo:"), false},
		{chann, channel(chann.Url), false},
		{header(chann), header(chann), true},
		{chann_header2, chann_header2, true},
		{chann_header3, chann_header3, true},
		{header(chann), chann_header2, false},
		{header(chann), chann_header3, false},
		{header(chann), chann, false},
		{chann, header(chann), false},
		{ca(chann), ca(chann), true},
		{ca(chann), chann, false},
		{chann, ca(chann), false},
		{ca(header(chann)), ca(header(chann)), true},
		{chann_ca2, ca(chann), false},
		{chann, timeout(chann), false},
	} {
		if actual := tc.channelA.IsEqual(tc.channelB); tc.expected != actual {
			t.Fatalf(
				"test case %d: Comparison:\n-%+v\n+%+v\nexpected=%v: actual=%v",
				i, tc.channelA, tc.channelB, tc.expected, actual,
			)
		}
	}
}

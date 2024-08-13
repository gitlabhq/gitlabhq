package api

import (
	"net/http"
	"testing"

	"github.com/stretchr/testify/require"
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
	channel.CAPem = `-----BEGIN CERTIFICATE-----
MIIDJzCCAg+gAwIBAgIUVIL4Kds+1NAurWOrbruWOED104wwDQYJKoZIhvcNAQEL
BQAwIzEhMB8GA1UEAwwYd29ya2hvcnNlLXdlYnNvY2tldC10ZXN0MB4XDTIyMDMw
MjE2Mjk1MloXDTIzMDMwMjE2Mjk1MlowIzEhMB8GA1UEAwwYd29ya2hvcnNlLXdl
YnNvY2tldC10ZXN0MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAtvDg
SlvuPROo6BeyjRVLYfS93rHV0bC+dm4waYFZpf+0nfiajXa5oZM+I6P3Vlim6OFg
kkq1KX8X4ZftEOdsA2dKgaELpsaIOYeeKgvWQgF7+oxCB9CBt67wpI6s8oWUTe2O
mvQqicPdZ53pbv+qRPJcfsckWXWHFM99lOJmeMoA56VoZNNrbmeDPX4+um2fr6Cp
pJ7pJ2UkkJeAWTAZHsYNJClLuIAw7J/AjXJf7gWQkUO2BFKgxC618Un2aQqw+EAX
N81Nn2lPqxsgu1y5VLOng7ZxpvxpDEpsRQoe+sglee+pbMqbpI1OC7tvr6Nvop4H
BmYkHxDDe00JVJXRLwIDAQABo1MwUTAdBgNVHQ4EFgQUnfnpeFXJwCtr3odLWcQa
Fe50ZeIwHwYDVR0jBBgwFoAUnfnpeFXJwCtr3odLWcQaFe50ZeIwDwYDVR0TAQH/
BAUwAwEB/zANBgkqhkiG9w0BAQsFAAOCAQEAXJzX6qcWIRff/k6Vt5OugvGWPYqg
dl2cc/usxmM42q7RfFcgvePjHN0hDTMJFgC8//vmm+i1oTh36ULZebeKH6HyN6gj
wj2a+xDElqRSVkO2xy8LNX5AsI0n+5G/oxVX7cH9eW16zRVntZrQg+4Fc6K6as0l
qF8ccAdMixYh6obn1ij3ThZNwhMTDloQ50LI+ydZpBXPn+LugmpcP6VSE3Wz98/s
FZuUBARp/QnNJO/2eWIZ1K+W/e9U31QhxFxM4niNS21NsZ6yqd/IWrR76Mkxv1PI
h7UpUazMISSqd/AvvZ8XDiAlsHCuppx3AJ4tzE73mdHP5Sf2DWhx/hwuZg==
-----END CERTIFICATE-----
`

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

	channel = ca(channel)
	dialer = channel.Dialer()

	subjectOfTestCertificate := []byte{48, 35, 49, 33, 48, 31, 6, 3, 85, 4, 3, 12, 24, 119, 111, 114, 107, 104, 111, 114, 115, 101, 45, 119, 101, 98, 115, 111, 99, 107, 101, 116, 45, 116, 101, 115, 116}
	//lint:ignore SA1019 Ignore the deprecation warnings
	// nolint:staticcheck // Ignore the deprecation warnings
	require.Contains(t, dialer.TLSClientConfig.RootCAs.Subjects(), subjectOfTestCertificate)
}

func TestIsEqual(t *testing.T) {
	chann := channel("ws:", "foo")

	channHeader2 := header(chann, "extra")
	channHeader3 := header(chann)
	channHeader3.Header.Add("Extra", "extra")

	channCa2 := ca(chann)
	channCa2.CAPem = "other value"

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
		{channHeader2, channHeader2, true},
		{channHeader3, channHeader3, true},
		{header(chann), channHeader2, false},
		{header(chann), channHeader3, false},
		{header(chann), chann, false},
		{chann, header(chann), false},
		{ca(chann), ca(chann), true},
		{ca(chann), chann, false},
		{chann, ca(chann), false},
		{ca(header(chann)), ca(header(chann)), true},
		{channCa2, ca(chann), false},
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

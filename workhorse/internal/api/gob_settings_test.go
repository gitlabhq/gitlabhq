package api

import (
	"testing"
)

func TestGOBSettings(t *testing.T) {
	for _, tc := range []struct {
		valid bool
		desc  string
		gob   *GOBSettings
	}{
		{
			desc:  "should return error when gob is nil",
			valid: false,
			gob:   nil,
		}, {
			desc:  "should return error when no backend",
			valid: false,
			gob: &GOBSettings{
				Headers: map[string]string{},
				Backend: "",
			},
		},
		{
			desc:  "should return error when backend not a valid URL",
			valid: false,
			gob: &GOBSettings{
				Headers: map[string]string{},
				Backend: "invalid",
			},
		},
		{
			desc:  "should return error when backend protocol not supported",
			valid: false,
			gob: &GOBSettings{
				Headers: map[string]string{},
				Backend: "tcp://observe.gitlab.com",
			},
		},
		{
			desc:  "should be valid when backend protocol is http",
			valid: true,
			gob: &GOBSettings{
				Headers: map[string]string{},
				Backend: "http://observe.gitlab.com",
			},
		},
		{
			desc:  "should be valid when backend protocol is https",
			valid: true,
			gob: &GOBSettings{
				Headers: map[string]string{},
				Backend: "https://observe.gitlab.com",
			},
		},
	} {
		t.Run(tc.desc, func(t *testing.T) {
			if _, err := tc.gob.Upstream(); (err != nil) == tc.valid {
				t.Fatalf("valid=%v: %s: %+v", tc.valid, err, tc.gob)
			}
		})
	}
}

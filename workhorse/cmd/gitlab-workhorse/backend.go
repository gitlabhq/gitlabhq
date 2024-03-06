package main

import (
	"fmt"
	"net/url"
)

func parseAuthBackend(authBackend string) (*url.URL, error) {
	backendURL, err := url.Parse(authBackend)
	if err != nil {
		return nil, err
	}

	if backendURL.Host == "" {
		backendURL, err = url.Parse("http://" + authBackend)
		if err != nil {
			return nil, err
		}
	}

	if backendURL.Scheme != "http" && backendURL.Scheme != "https" {
		return nil, fmt.Errorf("invalid scheme, only 'http' and 'https' are allowed: %q", authBackend)
	}

	if backendURL.Host == "" {
		return nil, fmt.Errorf("missing host in %q", authBackend)
	}

	return backendURL, nil
}

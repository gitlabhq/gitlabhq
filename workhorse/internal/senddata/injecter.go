// Package senddata provides functionality for injecting data into HTTP responses
package senddata

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
)

// Injecter defines the interface for data injection
type Injecter interface {
	Match(string) bool
	Inject(http.ResponseWriter, *http.Request, string)
	Name() string
}

// Prefix represents a prefix for injection
type Prefix string

// Match checks if the given string starts with the prefix
func (p Prefix) Match(s string) bool {
	return strings.HasPrefix(s, string(p))
}

// Unpack decodes and unmarshals the sendData string
func (p Prefix) Unpack(result interface{}, sendData string) error {
	jsonBytes, err := base64.URLEncoding.DecodeString(strings.TrimPrefix(sendData, string(p)))
	if err != nil {
		return err
	}
	if err := json.Unmarshal(jsonBytes, result); err != nil {
		return err
	}
	return nil
}

// Name returns the name of the prefix without the colon suffix
func (p Prefix) Name() string {
	return strings.TrimSuffix(string(p), ":")
}

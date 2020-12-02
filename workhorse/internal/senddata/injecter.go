package senddata

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strings"
)

type Injecter interface {
	Match(string) bool
	Inject(http.ResponseWriter, *http.Request, string)
	Name() string
}

type Prefix string

func (p Prefix) Match(s string) bool {
	return strings.HasPrefix(s, string(p))
}

func (p Prefix) Unpack(result interface{}, sendData string) error {
	jsonBytes, err := base64.URLEncoding.DecodeString(strings.TrimPrefix(sendData, string(p)))
	if err != nil {
		return err
	}
	if err := json.Unmarshal([]byte(jsonBytes), result); err != nil {
		return err
	}
	return nil
}

func (p Prefix) Name() string {
	return strings.TrimSuffix(string(p), ":")
}

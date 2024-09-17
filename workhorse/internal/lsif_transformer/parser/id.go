package parser

import (
	"encoding/json"
	"errors"
	"strconv"
)

const (
	minID = 1
	maxID = 20 * 1000 * 1000
)

// ID represents a unique identifier used in the parser
type ID int32

// UnmarshalJSON parses the JSON-encoded data
func (id *ID) UnmarshalJSON(b []byte) error {
	if len(b) > 0 && b[0] != '"' {
		if err := id.unmarshalInt(b); err != nil {
			return err
		}
	} else {
		if err := id.unmarshalString(b); err != nil {
			return err
		}
	}

	if *id < minID || *id > maxID {
		return errors.New("json: id is invalid")
	}

	return nil
}

func (id *ID) unmarshalInt(b []byte) error {
	return json.Unmarshal(b, (*int32)(id))
}

func (id *ID) unmarshalString(b []byte) error {
	var s string
	if err := json.Unmarshal(b, &s); err != nil {
		return err
	}

	i, err := strconv.Atoi(s)
	if err != nil {
		return err
	}

	*id = ID(i) //nolint:gosec

	return nil
}

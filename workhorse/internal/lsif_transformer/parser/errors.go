package parser

import (
	"errors"
	"strings"
)

func combineErrors(errsOrNil ...error) error {
	var errs []error
	for _, err := range errsOrNil {
		if err != nil {
			errs = append(errs, err)
		}
	}

	if len(errs) == 0 {
		return nil
	}

	if len(errs) == 1 {
		return errs[0]
	}

	var msgs []string
	for _, err := range errs {
		msgs = append(msgs, err.Error())
	}

	return errors.New(strings.Join(msgs, "\n"))
}

package parser

import (
	"errors"
	"testing"

	"github.com/stretchr/testify/require"
)

type customErr struct {
	err string
}

func (e customErr) Error() string {
	return e.err
}

func TestCombineErrors(t *testing.T) {
	err := combineErrors(nil, errors.New("first"), nil, customErr{"second"})
	require.EqualError(t, err, "first\nsecond")

	err = customErr{"custom error"}
	require.Equal(t, err, combineErrors(nil, err, nil))

	require.Nil(t, combineErrors(nil, nil, nil))
}

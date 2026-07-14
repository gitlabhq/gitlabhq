package command

import (
	"errors"
	"os/exec"
	"testing"

	"github.com/stretchr/testify/require"
)

type ErrorWithExitCode struct {
	exitCode int
}

func (e ErrorWithExitCode) Error() string {
	return "Error that responds to ExitCode()"
}

func (e ErrorWithExitCode) ExitCode() int {
	return e.exitCode
}

func TestExitStatus(t *testing.T) {
	tests := []struct {
		name     string
		err      error
		exitCode int
		ok       bool
	}{
		{
			name:     "error responds to ExitCode()",
			err:      ErrorWithExitCode{exitCode: 0},
			exitCode: 0,
			ok:       true,
		},
		{
			name:     "error is not nil",
			err:      errors.New("some generic error"),
			exitCode: -1,
			ok:       false,
		},
		{
			name:     "else",
			err:      nil,
			exitCode: 0,
			ok:       false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			exitCode, ok := ExitStatus(tt.err)

			require.Equal(t, tt.exitCode, exitCode)
			require.Equal(t, tt.ok, ok)
		})
	}
}

func TestKillProcessGroup(t *testing.T) {
	tests := []struct {
		name       string
		cmd        *exec.Cmd
		start      bool
		wantErr    bool
		wantExeErr bool
	}{
		{
			name:    "command is nil",
			cmd:     nil,
			start:   false,
			wantErr: false,
		},
		{
			name:    "command not started",
			cmd:     exec.Command("sleep"),
			start:   false,
			wantErr: true,
		},
		{
			name:       "command started",
			cmd:        exec.Command("sleep"),
			start:      true,
			wantErr:    true,
			wantExeErr: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if tt.start == true {
				tt.cmd.Start()
			}

			err := KillProcessGroup(tt.cmd)
			switch {
			case !tt.wantErr:
				require.NoError(t, err)
			case tt.wantExeErr:
				var exitErr *exec.ExitError
				require.ErrorAs(t, err, &exitErr)
			default:
				require.Error(t, err)
			}
		})
	}
}

func TestKillProcessGroupAfterWait(t *testing.T) {
	// exits immediately
	cmd := exec.Command("true")

	require.NoError(t, cmd.Start())
	require.NoError(t, cmd.Wait())

	err := KillProcessGroup(cmd)
	require.NoError(t, err)
}

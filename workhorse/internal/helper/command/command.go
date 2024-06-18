// Package command provides helper functions for working with commands and processes
package command

import (
	"os/exec"
	"syscall"
)

// ExitStatus returns the exit code of an error if it implements the ExitCode() method
func ExitStatus(err error) (int, bool) {
	if v, ok := err.(interface{ ExitCode() int }); ok {
		return v.ExitCode(), true
	} else if err != nil {
		return -1, false
	}
	return 0, false
}

// KillProcessGroup sends a SIGTERM signal to the process group of the given command
func KillProcessGroup(cmd *exec.Cmd) error {
	if cmd == nil {
		return nil
	}

	if p := cmd.Process; p != nil && p.Pid > 0 {
		// Send SIGTERM to the process group of cmd
		_ = syscall.Kill(-p.Pid, syscall.SIGTERM)
	}

	// reap our child process
	return cmd.Wait()
}

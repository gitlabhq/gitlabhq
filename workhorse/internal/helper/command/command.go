package command

import (
	"os/exec"
	"syscall"
)

func ExitStatus(err error) (int, bool) {
	if v, ok := err.(interface{ ExitCode() int }); ok {
		return v.ExitCode(), true
	} else if err != nil {
		return -1, false
	} else {
		return 0, false
	}
}

func KillProcessGroup(cmd *exec.Cmd) {
	if cmd == nil {
		return
	}

	if p := cmd.Process; p != nil && p.Pid > 0 {
		// Send SIGTERM to the process group of cmd
		syscall.Kill(-p.Pid, syscall.SIGTERM)
	}

	// reap our child process
	cmd.Wait()
}

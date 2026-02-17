// Package puma provides types for interacting with Puma's control server and readiness endpoints.
package puma

// ControlResponse represents the JSON response from Puma's control server
type ControlResponse struct {
	StartedAt     string   `json:"started_at"`
	Workers       int      `json:"workers"`
	Phase         int      `json:"phase"`
	BootedWorkers int      `json:"booted_workers"`
	OldWorkers    int      `json:"old_workers"`
	WorkerStatus  []Worker `json:"worker_status"`
}

// Worker represents a Puma worker's status
type Worker struct {
	StartedAt   string       `json:"started_at"`
	PID         int          `json:"pid"`
	Index       int          `json:"index"`
	Phase       int          `json:"phase"`
	Booted      bool         `json:"booted"`
	LastCheckin string       `json:"last_checkin"`
	LastStatus  WorkerStatus `json:"last_status"`
}

// WorkerStatus represents the detailed status of a Puma worker
type WorkerStatus struct {
	Backlog       int `json:"backlog"`
	Running       int `json:"running"`
	PoolCapacity  int `json:"pool_capacity"`
	MaxThreads    int `json:"max_threads"`
	RequestsCount int `json:"requests_count"`
}

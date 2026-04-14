# GitLab Workhorse - Agent Guide

This document provides guidance for AI agents working with the GitLab Workhorse codebase.

## Project Overview

**GitLab Workhorse** is a smart reverse proxy for GitLab written in Go. It sits in front of Puma and intercepts HTTP requests to handle resource-intensive and long-running operations, including file uploads, downloads, Git operations, and artifact processing.

## Project Structure

```
workhorse/
├── cmd/                          # Executable commands
│   ├── gitlab-workhorse/        # Main reverse proxy server
│   ├── gitlab-resize-image/     # Image resizing utility
│   ├── gitlab-zip-cat/          # ZIP file concatenation utility
│   └── gitlab-zip-metadata/     # ZIP file metadata extraction utility
├── internal/                     # Internal Go packages (not exported)
│   ├── api/                     # API communication and handlers
│   ├── upload/                  # File upload handling
│   ├── download/                # File download handling
│   ├── git/                     # Git operations
│   ├── gitaly/                  # Gitaly integration
│   ├── proxy/                   # HTTP proxy logic
│   ├── senddata/                # Response data sending
│   ├── sendfile/                # File sending utilities
│   ├── sendurl/                 # URL-based sending
│   ├── artifacts/               # Build artifacts handling
│   ├── builds/                  # Build-related operations
│   ├── lsif_transformer/        # LSIF (Language Server Index Format) transformation
│   ├── zipartifacts/            # ZIP artifact operations
│   ├── imageresizer/            # Image resizing operations
│   ├── redis/                   # Redis integration
│   ├── channel/                 # Channel operations
│   ├── circuitbreaker/          # Circuit breaker pattern implementation
│   ├── queueing/                # Request queueing
│   ├── metrics/                 # Prometheus metrics
│   ├── config/                  # Configuration management
│   ├── log/                     # Logging utilities
│   ├── headers/                 # HTTP header handling
│   ├── transport/               # HTTP transport configuration
│   ├── upstream/                # Upstream server communication
│   ├── healthcheck/             # Health check endpoints
│   ├── version/                 # Version information
│   ├── helper/                  # Helper utilities
│   ├── testhelper/              # Testing utilities
│   ├── utils/                   # General utilities
│   ├── badgateway/              # Bad gateway error handling
│   ├── bodylimit/               # Request body size limiting
│   ├── dependencyproxy/         # Dependency proxy handling
│   ├── forwardheaders/          # Header forwarding
│   ├── gob/                     # Go binary serialization
│   ├── httprs/                  # HTTP response streaming
│   ├── listener/                # Network listener management
│   ├── rejectmethods/           # HTTP method rejection
│   ├── secret/                  # Secret management
│   ├── staticpages/             # Static page serving
│   ├── urlprefix/               # URL prefix handling
│   └── ai_assist/duoworkflow    # AI assistance features. Proxies AI-related requests to Duo Workflow Service
├── testdata/                     # Test fixtures and data files
├── _support/                     # Development scripts and tools
├── Makefile                      # Build and test automation
├── go.mod / go.sum              # Go module dependencies
├── README.md                     # Project documentation
└── VERSION                       # Version file
```

## Development Workflow

### Building

```bash
make gitlab-workhorse
```

### Testing

```bash
make test              # Run all tests
make test-race         # Run tests with race detector
make test-coverage     # Generate coverage report
```

To run a single test:

```
go test <package-path> -count=1
```

For example:

```
go test ./internal/ai_assist/duoworkflow -count=1
```


### Code Quality

```bash
make verify            # Run all verification checks
make lint              # Run linter
make vet               # Run go vet
make fmt               # Format code
make golangci           # Run golangci-lint
```

## Testing Guidelines

### Test Organization

- Unit tests: `*_test.go` files in same package
- Integration tests: Use `GITALY_ADDRESS` environment variable
- Test data: Located in `testdata/`
- Mock helpers: `internal/testhelper/`

### Test Patterns

```go
// Table-driven tests are preferred
func TestFeature(t *testing.T) {
    tests := []struct {
        name    string
        input   interface{}
        want    interface{}
        wantErr bool
    }{
        // test cases
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            // test logic
        })
    }
}
```

## Code Style & Standards

- **Formatting**: Use `goimports` (enforced by `make fmt`)
- **Linting**: Must pass `golangci-lint` checks, while `_support/lint_last_known_acceptable.txt` contains the exceptions.
- **Naming**: Follow Go conventions (CamelCase for exported, camelCase for unexported)
- **Error Handling**: Explicit error returns, no panic in production code
- **Comments**: Exported functions must have doc comments
- **Testing**: Aim for >80% coverage on critical paths

## Important Files to Know

| File | Purpose |
|------|---------|
| `cmd/gitlab-workhorse/main.go` | Entry point, server setup |
| `go.mod` | Dependency management |
| `Makefile` | Build automation |

## Related Documentation

- [Workhorse Development](https://docs.gitlab.com/ee/development/workhorse/)

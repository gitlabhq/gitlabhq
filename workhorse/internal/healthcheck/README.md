# Health Check System

This document describes the health check system in GitLab Workhorse that supports readiness checks.

## Overview

The health check system provides a server that handles readiness checks:

- **Readiness checks** (`/readiness`): Determine if the service is ready to accept traffic

## Configuration

### Recommended Configuration

The health check system uses a `health_check_listener` configuration:

```toml
[health_check_listener]
  network = "tcp"
  addr = "localhost:8182"
  readiness_probe_url = "http://localhost:8080/-/readiness"
  puma_control_url = "http://localhost:9293"
  check_interval = "5s"
  timeout = "1s"
  graceful_shutdown_delay = "10s"
  max_consecutive_failures = 3
  min_successful_probes = 1
```

## Configuration Options

- `network`: Network type (`tcp`, `tcp4`, `tcp6`, `unix`)
- `addr`: Address to listen on (e.g., `localhost:8182`)
- `check_interval`: How often to perform health checks (default: `2s`)
- `timeout`: Timeout for individual health check requests (default: `1s`)
- `graceful_shutdown_delay`: How long to remain unhealthy after shutdown signal (default: `10s`)
- `max_consecutive_failures`: Number of consecutive failures before marking readiness as unhealthy (default: `3`)
- `min_successful_probes`: Number of successful probes required for readiness to become healthy (default: `2`)
- `readiness_probe_url`: URL of Puma's readiness endpoint (default: `authBackend + "/-/readiness"`)
- `puma_control_url`: URL of Puma's control server (optional, for readiness checks only)

## Health Check Types

### Readiness Checks (`/readiness`)

Readiness checks determine if the service is ready to accept traffic. They check:

- Puma readiness endpoint availability
- Puma control server statistics (if configured)
- Worker health and availability

**Behavior:**
- Starts as unhealthy (not ready)
- Requires `min_successful_probes` consecutive successes to become ready
- Uses `max_consecutive_failures` threshold before marking as not ready
- Becomes unhealthy during graceful shutdown

## HTTP Endpoints

The health check listener exposes HTTP endpoints that return JSON responses:

### Readiness Endpoint (`/readiness`)

#### Healthy Response (200 OK)

```json
{
  "checks": {
    "puma_readiness": {
      "control_duration_s": 0.00176875,
      "control_server": true,
      "control_server_last_scrape_time": "2025-10-02T21:55:43Z",
      "healthy": true,
      "readiness_duration_s": 0.028158458,
      "readiness_endpoint": true,
      "readiness_last_scrape_time": "2025-10-02T21:55:43Z"
    }
  },
  "health_thresholds": {
    "max_consecutive_failures": 3,
    "min_successful_probes": 1
  },
  "metrics": {
    "consecutive_failures": 0,
    "consecutive_successes": 1
  },
  "ready": true
}
```

#### Unhealthy Response (503 Service Unavailable)

```json
{
  "checks": {
    "puma_readiness": {
      "control_duration_s": 0,
      "control_server": false,
      "control_server_last_scrape_time": "2025-10-02T21:56:13Z",
      "healthy": false,
      "readiness_duration_s": 0,
      "readiness_endpoint": false
    }
  },
  "health_thresholds": {
    "max_consecutive_failures": 3,
    "min_successful_probes": 1
  },
  "last_error": "puma control server check failed: Get \"http://localhost:9293/stats\": dial tcp [::1]:9293: connect: connection refused",
  "metrics": {
    "consecutive_failures": 3,
    "consecutive_successes": 0
  },
  "ready": false
}
```

## Prometheus Metrics

The health check system exposes several Prometheus metrics:

### Overall Status Metrics
- `workhorse_readiness_status`: Overall readiness status (1 = ready, 0 = not ready)

### Error Metrics
- `workhorse_readiness_errors_total`: Total number of readiness check errors

### Performance Metrics
- `workhorse_health_check_duration_seconds`: Duration of health checks

### Individual Check Metrics
- `workhorse_readiness_puma_readiness_check`: Status of Puma readiness endpoint

## Graceful Shutdown

When Workhorse receives a SIGTERM signal:

1. **Readiness**: Immediately becomes unhealthy (503) to stop receiving new traffic
2. **Delay**: Waits for `graceful_shutdown_delay` to allow load balancers to drain traffic
3. **Shutdown**: Proceeds with normal shutdown after the delay

This approach eliminates 502 errors during deployments and provides smooth traffic transitions.

## Extending the System

### Adding New Checkers

Implement the `HealthChecker` interface:

```go
type MyChecker struct {
    name string
}

func (c *MyChecker) Name() string {
    return c.name
}

func (c *MyChecker) Check(ctx context.Context) CheckResult {
    // Perform your health check logic
    return CheckResult{
        Name:    c.name,
        Healthy: true,
        Details: map[string]interface{}{
            "your-field": "ok",
        },
    }
}
```

### Registering Custom Checkers

```go
// Add to readiness checks
server.AddReadinessChecker(NewMyChecker("my_readiness_check"))
```

## Troubleshooting

### Common Issues

1. **Health check endpoints not responding**
   - Verify `health_check_listener` is configured in config.toml
   - Check if the listen address is available
   - Review Workhorse startup logs for errors

2. **Readiness always unhealthy**
   - Check if `puma_readiness_url` is accessible
   - Verify Puma is running and healthy
   - Review consecutive failure/success thresholds

3. **Flapping health status**
   - Adjust `max_consecutive_failures` and `min_successful_probes`
   - Increase `timeout` values if checks are timing out
   - Review `check_interval` frequency

### Debug Logging

Enable debug logging to see detailed health check information:

```bash
gitlab-workhorse -logLevel debug
```

### Manual Testing

Test health check endpoints manually:

```bash
# Test readiness
curl -v http://localhost:8182/readiness
```

## Architecture

### Components

1. **Server**: Main server that manages readiness checks
2. **HealthChecker Interface**: Contract for individual health checkers
3. **PumaReadinessChecker**: Checks Puma's readiness endpoint and control server

### Flow

1. **Initialization**: Server starts with configured checkers
2. **Periodic Checks**: Runs health checks at configured intervals
3. **State Management**: Updates readiness status based on check results
4. **HTTP Serving**: Responds to health check requests with current status
5. **Metrics Export**: Updates Prometheus metrics continuously

## Migration from Legacy System

### Benefits of the Unified System

- **Better Logic**: Improved consecutive failure/success handling
- **Enhanced Metrics**: More detailed Prometheus metrics
- **Future-Proof**: Active development and new features

## See Also

- [config.toml.example](../../config.toml.example) - Configuration examples

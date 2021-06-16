# Workhorse configuration

For historical reasons Workhorse uses both command line flags, a configuration file and environment variables.

All new configuration options that get added to Workhorse should go into the configuration file.

## CLI options

```
  gitlab-workhorse [OPTIONS]

Options:
  -apiCiLongPollingDuration duration
      Long polling duration for job requesting for runners (default 50ns)
  -apiLimit uint
      Number of API requests allowed at single time
  -apiQueueDuration duration
      Maximum queueing duration of requests (default 30s)
  -apiQueueLimit uint
      Number of API requests allowed to be queued
  -authBackend string
      Authentication/authorization backend (default "http://localhost:8080")
  -authSocket string
      Optional: Unix domain socket to dial authBackend at
  -cableBackend string
      Optional: ActionCable backend (default authBackend)
  -cableSocket string
      Optional: Unix domain socket to dial cableBackend at (default authSocket)
  -config string
      TOML file to load config from
  -developmentMode
      Allow the assets to be served from Rails app
  -documentRoot string
      Path to static files content (default "public")
  -listenAddr string
      Listen address for HTTP server (default "localhost:8181")
  -listenNetwork string
      Listen 'network' (tcp, tcp4, tcp6, unix) (default "tcp")
  -listenUmask int
      Umask for Unix socket
  -logFile string
      Log file location
  -logFormat string
      Log format to use defaults to text (text, json, structured, none) (default "text")
  -pprofListenAddr string
      pprof listening address, e.g. 'localhost:6060'
  -prometheusListenAddr string
      Prometheus listening address, e.g. 'localhost:9229'
  -proxyHeadersTimeout duration
      How long to wait for response headers when proxying the request (default 5m0s)
  -secretPath string
      File with secret key to authenticate with authBackend (default "./.gitlab_workhorse_secret")
  -version
      Print version and exit
```

The 'auth backend' refers to the GitLab Rails application. The name is
a holdover from when GitLab Workhorse only handled Git push/pull over
HTTP.

GitLab Workhorse can listen on either a TCP or a Unix domain socket. It
can also open a second listening TCP listening socket with the Go
[net/http/pprof profiler server](http://golang.org/pkg/net/http/pprof/).

GitLab Workhorse can listen on redis events (currently only builds/register
for runners). This requires you to pass a valid TOML config file via
`-config` flag.
For regular setups it only requires the following (replacing the string
with the actual socket)

## Redis

GitLab Workhorse integrates with Redis to do long polling for CI build
requests. This is configured via two things:

-   Redis settings in the TOML config file
-   The `-apiCiLongPollingDuration` command line flag to control polling
    behavior for CI build requests

It is OK to enable Redis in the config file but to leave CI polling
disabled; this just results in an idle Redis pubsub connection. The
opposite is not possible: CI long polling requires a correct Redis
configuration.

Below we discuss the options for the `[redis]` section in the config
file.

```
[redis]
URL = "unix:///var/run/gitlab/redis.sock"
Password = "my_awesome_password"
Sentinel = [ "tcp://sentinel1:23456", "tcp://sentinel2:23456" ]
SentinelMaster = "mymaster"
```

- `URL` takes a string in the format `unix://path/to/redis.sock` or
`tcp://host:port`.
- `Password` is only required if your redis instance is password-protected
- `Sentinel` is used if you are using Sentinel.
  *NOTE* that if both `Sentinel` and `URL` are given, only `Sentinel` will be used

Optional fields are as follows:
```
[redis]
DB = 0
MaxIdle = 1
MaxActive = 1
```

- `DB` is the Database to connect to. Defaults to `0`
- `MaxIdle` is how many idle connections can be in the redis-pool at once. Defaults to 1
- `MaxActive` is how many connections the pool can keep. Defaults to 1

## Relative URL support

If you are mounting GitLab at a relative URL, e.g.
`example.com/gitlab`, then you should also use this relative URL in
the `authBackend` setting:

```
gitlab-workhorse -authBackend http://localhost:8080/gitlab
```

## Interaction of authBackend and authSocket

The interaction between `authBackend` and `authSocket` can be a bit
confusing. It comes down to: if `authSocket` is set it overrides the
_host_ part of `authBackend` but not the relative path.

In table form:

|authBackend|authSocket|Workhorse connects to?|Rails relative URL|
|---|---|---|---|
|unset|unset|`localhost:8080`|`/`|
|`http://localhost:3000`|unset|`localhost:3000`|`/`|
|`http://localhost:3000/gitlab`|unset|`localhost:3000`|`/gitlab`|
|unset|`/path/to/socket`|`/path/to/socket`|`/`|
|`http://localhost:3000`|`/path/to/socket`|`/path/to/socket`|`/`|
|`http://localhost:3000/gitlab`|`/path/to/socket`|`/path/to/socket`|`/gitlab`|

The same applies to `cableBackend` and `cableSocket`.

## Error tracking

GitLab-Workhorse supports remote error tracking with
[Sentry](https://sentry.io). To enable this feature set the
`GITLAB_WORKHORSE_SENTRY_DSN` environment variable.
You can also set the `GITLAB_WORKHORSE_SENTRY_ENVIRONMENT` environment variable to
use the Sentry environment functionality to separate staging, production and
development.

Omnibus (`/etc/gitlab/gitlab.rb`):

```
gitlab_workhorse['env'] = {
    'GITLAB_WORKHORSE_SENTRY_DSN' => 'https://foobar'
    'GITLAB_WORKHORSE_SENTRY_ENVIRONMENT' => 'production'
}
```

Source installations (`/etc/default/gitlab`):

```
export GITLAB_WORKHORSE_SENTRY_DSN='https://foobar'
export GITLAB_WORKHORSE_SENTRY_ENVIRONMENT='production'
```

## Distributed Tracing

Workhorse supports distributed tracing through [LabKit][] using [OpenTracing APIs](https://opentracing.io).

By default, no tracing implementation is linked into the binary, but different OpenTracing providers can be linked in using [build tags][build-tags]/[build constraints][build-tags]. This can be done by setting the `BUILD_TAGS` make variable.

For more details of the supported providers, see LabKit, but as an example, for Jaeger tracing support, include the tags: `BUILD_TAGS="tracer_static tracer_static_jaeger"`.

```shell
make BUILD_TAGS="tracer_static tracer_static_jaeger"
```

Once Workhorse is compiled with an opentracing provider, the tracing configuration is configured via the `GITLAB_TRACING` environment variable.

For example:

```shell
GITLAB_TRACING=opentracing://jaeger ./gitlab-workhorse
```

## Continuous Profiling

Workhorse supports continuous profiling through [LabKit][] using [Stackdriver Profiler](https://cloud.google.com/profiler).

By default, the Stackdriver Profiler implementation is linked in the binary using [build tags][build-tags], though it's not
required and can be skipped.

For example:

```shell
make BUILD_TAGS=""
```

Once Workhorse is compiled with Continuous Profiling, the profiler configuration can be set via `GITLAB_CONTINUOUS_PROFILING`
environment variable.

For example:

```shell
GITLAB_CONTINUOUS_PROFILING="stackdriver?service=workhorse&service_version=1.0.1&project_id=test-123 ./gitlab-workhorse"
```

More information about see the [LabKit monitoring docs](https://gitlab.com/gitlab-org/labkit/-/blob/master/monitoring/doc.go).

[LabKit]: https://gitlab.com/gitlab-org/labkit/
[build-tags]: https://golang.org/pkg/go/build/#hdr-Build_Constraints

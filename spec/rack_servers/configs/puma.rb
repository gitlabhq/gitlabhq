# frozen_string_literal: true

# The directory to operate out of.
#
# The default is the current directory.
#
directory '$WORKING_DIR'

# Configure "min" to be the minimum number of threads to use to answer
# requests and "max" the maximum.
#
# The default is "0, 16".
threads 1, 10

# By default, workers accept all requests and queue them to pass to handlers.
# When false, workers accept the number of simultaneous requests configured.
#
# Queueing requests generally improves performance, but can cause deadlocks if
# the app is waiting on a request to itself. See https://github.com/puma/puma/issues/612
#
# When set to false this may require a reverse proxy to handle slow clients and
# queue requests before they reach puma. This is due to disabling HTTP keepalive
queue_requests false

# Bind the server to "url". "tcp://", "unix://" and "ssl://" are the only
# accepted protocols.
bind 'unix://$WORKING_DIR/tmp/tests/puma.socket'

workers 1

def require_from_app(path)
  # We cannot control where this file is, so can't use require_relative directly,
  # but we know that working_directory and `Dir.pwd` will always be the root of
  # the application
  require 'pathname'
  required_module_path = Pathname.new(Dir.pwd()) + path
  require_relative required_module_path.to_s
end

require_from_app "./lib/gitlab/cluster/lifecycle_events"
require_from_app "./lib/gitlab/cluster/puma_worker_killer_initializer"

before_fork do
  Gitlab::Cluster::PumaWorkerKillerInitializer.start(@config)
  Gitlab::Cluster::LifecycleEvents.signal_before_fork
end

Gitlab::Cluster::LifecycleEvents.set_puma_options @config.options
on_worker_boot do
  Gitlab::Cluster::LifecycleEvents.signal_worker_start
  File.write('tmp/tests/puma-worker-ready', Process.pid)
end

on_restart do
  Gitlab::Cluster::LifecycleEvents.signal_master_restart
end

# Preload the application before starting the workers; this conflicts with
# phased restart feature. (off by default)

preload_app!

tag 'gitlab-puma-worker'

# Verifies that all workers have checked in to the master process within
# the given timeout. If not the worker process will be restarted. Default
# value is 60 secon ds.
#
worker_timeout 60

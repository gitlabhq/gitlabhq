# frozen_string_literal: true

# Note: this file is used for testing puma in `spec/rack_servers/puma_spec.rb` only
# Note: as per the convention in `config/puma.example.development.rb`,
# this file will replace `/home/git` with the actual working directory

directory '/home/git'
threads 1, 10
queue_requests false
pidfile '/home/git/gitlab/tmp/pids/puma.pid'
bind 'unix:///home/git/gitlab/tmp/tests/puma.socket'
workers 1
preload_app!
worker_timeout 60

require_relative "/home/git/gitlab/lib/gitlab/cluster/lifecycle_events"
require_relative "/home/git/gitlab/lib/gitlab/cluster/puma_worker_killer_initializer"

before_fork do
  Gitlab::Cluster::PumaWorkerKillerInitializer.start @config.options
  Gitlab::Cluster::LifecycleEvents.do_before_fork
end

Gitlab::Cluster::LifecycleEvents.set_puma_options @config.options
on_worker_boot do
  Gitlab::Cluster::LifecycleEvents.do_worker_start
  File.write('/home/git/gitlab/tmp/tests/puma-worker-ready', Process.pid)
end

on_restart do
  Gitlab::Cluster::LifecycleEvents.do_master_restart
end

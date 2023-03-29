# frozen_string_literal: true

require 'sidekiq'
require_relative 'config'
require_relative '../support/utils'

EXPECTED_NUM_TIMES_BEEN_RUN = 3
NUM_WORKERS = EXPECTED_NUM_TIMES_BEEN_RUN + 1

Sidekiq.redis(&:flushdb)

pids = spawn_workers(NUM_WORKERS)

RetryTestWorker.perform_async('TERM', 60)

sleep 300

Sidekiq.redis do |redis|
  times_has_been_run = redis.get('times_has_been_run').to_i
  assert 'The job has been run', times_has_been_run, EXPECTED_NUM_TIMES_BEEN_RUN
end

assert 'Found interruption exhausted jobs', Sidekiq::InterruptedSet.new.size, 1

stop_workers(pids)

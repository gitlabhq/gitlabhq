# frozen_string_literal: true

require_relative '../../lib/sidekiq-reliable-fetch'
require_relative 'worker'

REDIS_FINISHED_LIST = 'reliable-fetcher-finished-jids'

NUMBER_OF_WORKERS = ENV['NUMBER_OF_WORKERS'] || 10
NUMBER_OF_JOBS = ENV['NUMBER_OF_JOBS'] || 1000
NUMBER_OF_DUPLICATE_JOBS_ALLOWED = ENV['NUMBER_OF_DUPLICATE_JOBS_ALLOWED'] || 10
JOB_FETCHER = (ENV['JOB_FETCHER'] || :semi).to_sym # :basic, :semi, :reliable
NUMBER_OF_JOBS_LOST_ALLOWED = ENV['NUMBER_OF_JOBS_LOST_ALLOWED'] || (JOB_FETCHER == :reliable ? 0 : 3)
TEST_CLEANUP_INTERVAL = 20
TEST_LEASE_INTERVAL = 5
WAIT_CLEANUP = TEST_CLEANUP_INTERVAL +
               TEST_LEASE_INTERVAL +
               Sidekiq::ReliableFetch::HEARTBEAT_LIFESPAN

Sidekiq.configure_server do |config|
  if %i[semi reliable].include?(JOB_FETCHER)
    config[:semi_reliable_fetch] = (JOB_FETCHER == :semi)

    # We need to override these parameters to not wait too long
    # The default values are good for production use only
    # These will be ignored for :basic
    config[:cleanup_interval] = TEST_CLEANUP_INTERVAL
    config[:lease_interval] = TEST_LEASE_INTERVAL
    config[:queues] = ['default']

    Sidekiq::ReliableFetch.setup_reliable_fetch!(config)
  end
end

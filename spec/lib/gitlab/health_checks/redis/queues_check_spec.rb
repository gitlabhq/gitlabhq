require 'spec_helper'
require_relative '../simple_check_shared'

describe Gitlab::HealthChecks::Redis::QueuesCheck do
  include_examples 'simple_check', 'redis_queues_ping', 'RedisQueues', 'PONG'
end

require 'spec_helper'
require_relative '../simple_check_shared'

describe Gitlab::HealthChecks::Redis::RedisCheck do
  include_examples 'simple_check', 'redis_ping', 'Redis', 'PONG'
end

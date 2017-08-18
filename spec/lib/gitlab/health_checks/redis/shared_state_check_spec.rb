require 'spec_helper'
require_relative '../simple_check_shared'

describe Gitlab::HealthChecks::Redis::SharedStateCheck do
  include_examples 'simple_check', 'redis_shared_state_ping', 'RedisSharedState', 'PONG'
end

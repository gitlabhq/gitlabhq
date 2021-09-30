# frozen_string_literal: true

require 'spec_helper'
require_relative '../simple_check_shared'

RSpec.describe Gitlab::HealthChecks::Redis::RateLimitingCheck do
  include_examples 'simple_check', 'redis_rate_limiting_ping', 'RedisRateLimiting', 'PONG'
end

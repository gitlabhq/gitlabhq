require 'spec_helper'
require_relative '../simple_check_shared'

describe Gitlab::HealthChecks::Redis::CacheCheck do
  include_examples 'simple_check', 'redis_cache_ping', 'RedisCache', 'PONG'
end

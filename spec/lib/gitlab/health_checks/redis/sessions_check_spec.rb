# frozen_string_literal: true

require 'spec_helper'
require_relative '../simple_check_shared'

RSpec.describe Gitlab::HealthChecks::Redis::SessionsCheck do
  include_examples 'simple_check', 'redis_sessions_ping', 'RedisSessions', 'PONG'
end

# frozen_string_literal: true

require 'spec_helper'
require_relative '../simple_check_shared'

RSpec.describe Gitlab::HealthChecks::Redis::TraceChunksCheck do
  include_examples 'simple_check', 'redis_trace_chunks_ping', 'RedisTraceChunks', 'PONG'
end

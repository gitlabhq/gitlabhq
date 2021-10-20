# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::TraceChunks do
  include_examples "redis_new_instance_shared_examples", 'trace_chunks', Gitlab::Redis::SharedState
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::MemoryStoreTraceChunks, feature_category: :shared do
  include_examples "redis_new_instance_shared_examples", 'memory_store_trace_chunks', Gitlab::Redis::SharedState
end

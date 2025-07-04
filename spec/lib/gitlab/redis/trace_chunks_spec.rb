# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::TraceChunks do
  include_examples "redis_new_instance_shared_examples", 'trace_chunks', Gitlab::Redis::SharedState
  include_examples "multi_store_wrapper_shared_examples"

  it 'migrates from self to MemoryStoreTraceChunks' do
    expect(described_class.multistore.secondary_pool).to eq(described_class.pool)
    expect(described_class.multistore.primary_pool).to eq(Gitlab::Redis::MemoryStoreTraceChunks.pool)
  end
end

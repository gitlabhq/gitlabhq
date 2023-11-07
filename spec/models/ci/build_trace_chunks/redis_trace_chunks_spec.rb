# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTraceChunks::RedisTraceChunks, :clean_gitlab_redis_trace_chunks,
  feature_category:  :continuous_integration do
  let(:data_store) { described_class.new }
  let(:store_trait_with_data) { :redis_trace_chunks_with_data }
  let(:store_trait_without_data) { :redis_trace_chunks_without_data }

  it_behaves_like 'CI build trace chunk redis', Gitlab::Redis::TraceChunks
end

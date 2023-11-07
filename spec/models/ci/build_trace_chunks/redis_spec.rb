# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::BuildTraceChunks::Redis, :clean_gitlab_redis_shared_state do
  let(:data_store) { described_class.new }
  let(:store_trait_with_data) { :redis_with_data }
  let(:store_trait_without_data) { :redis_without_data }

  it_behaves_like 'CI build trace chunk redis', Gitlab::Redis::SharedState
end

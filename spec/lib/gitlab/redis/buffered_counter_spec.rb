# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::BufferedCounter, feature_category: :redis do
  include_examples "redis_new_instance_shared_examples", 'buffered_counter', Gitlab::Redis::SharedState
  include_examples "multi_store_wrapper_shared_examples"

  it 'migrates from self to SharedState' do
    expect(described_class.multistore.secondary_pool).to eq(described_class.pool)
    expect(described_class.multistore.primary_pool).to eq(Gitlab::Redis::SharedState.pool)
  end
end

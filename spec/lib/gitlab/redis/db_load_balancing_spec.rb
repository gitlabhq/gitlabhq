# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::DbLoadBalancing, feature_category: :scalability do
  include_examples "redis_new_instance_shared_examples", 'db_load_balancing', Gitlab::Redis::SharedState
  include_examples "redis_shared_examples"
  include_examples "multi_store_wrapper_shared_examples"

  it 'migrates from self to ClusterDbLoadBalancing' do
    expect(described_class.multistore.secondary_pool).to eq(described_class.pool)
    expect(described_class.multistore.primary_pool).to eq(Gitlab::Redis::ClusterDbLoadBalancing.pool)
  end
end

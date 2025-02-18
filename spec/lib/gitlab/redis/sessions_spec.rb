# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::Sessions, feature_category: :shared do
  include_examples "multi_store_wrapper_shared_examples"
  include_examples "redis_new_instance_shared_examples", 'sessions', Gitlab::Redis::SharedState

  describe '#store' do
    subject(:store) { described_class.store(namespace: described_class::SESSION_NAMESPACE) }

    # Check that Gitlab::Redis::Sessions is configured as RedisStore or ClusterStore
    it 'instantiates an instance of Redis::Store' do
      expect([::Redis::Store, ::Gitlab::Redis::ClusterStore].include?(store.class)).to eq(true)
    end
  end

  it 'migrates from self to ClusterSessions' do
    expect(described_class.multistore.secondary_pool).to eq(described_class.pool)
    expect(described_class.multistore.primary_pool).to eq(Gitlab::Redis::ClusterSessions.pool)
  end
end

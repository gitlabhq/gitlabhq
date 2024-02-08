# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::ClusterUtil, feature_category: :scalability do
  using RSpec::Parameterized::TableSyntax

  let(:router_stub) { instance_double(::RedisClient::Cluster::Router) }

  before do
    allow(::RedisClient::Cluster::Router).to receive(:new).and_return(router_stub)
  end

  describe '.cluster?' do
    context 'when MultiStore' do
      where(:pri_store, :sec_store, :expected_val) do
        :cluster | :cluster | true
        :cluster | :single  | true
        :single  | :cluster | true
        :single  | :single  | false
      end

      before do
        allow(router_stub).to receive(:node_keys).and_return([])

        allow(Gitlab::Redis::MultiStore).to receive(:same_redis_store?).and_return(false)
        skip_default_enabled_yaml_check
      end

      with_them do
        it 'returns expected value' do
          primary_redis = pri_store == :cluster ? Redis::Cluster.new(nodes: ['redis://localhost:6000']) : Redis.new
          secondary_redis = sec_store == :cluster ? Redis::Cluster.new(nodes: ['redis://localhost:6000']) : Redis.new
          primary_pool = ConnectionPool.new { primary_redis }
          secondary_pool = ConnectionPool.new { secondary_redis }
          multistore = Gitlab::Redis::MultiStore.new(primary_pool, secondary_pool, 'teststore')

          multistore.with_borrowed_connection do
            expect(described_class.cluster?(multistore)).to eq(expected_val)
          end
        end
      end
    end

    context 'when is not Redis::Cluster' do
      it 'returns false' do
        expect(described_class.cluster?(::Redis.new)).to be_falsey
      end
    end

    context 'when is Redis::Cluster' do
      it 'returns true' do
        expect(described_class.cluster?(Redis::Cluster.new(nodes: ['redis://localhost:6000']))).to be_truthy
      end
    end
  end
end

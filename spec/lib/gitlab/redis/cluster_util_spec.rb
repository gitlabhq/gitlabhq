# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::ClusterUtil, feature_category: :scalability do
  using RSpec::Parameterized::TableSyntax

  describe '.cluster?' do
    context 'when MultiStore' do
      let(:redis_cluster) { instance_double(::Redis::Cluster) }

      where(:pri_store, :sec_store, :expected_val) do
        :cluster | :cluster | true
        :cluster | :single  | true
        :single  | :cluster | true
        :single  | :single  | false
      end

      before do
        # stub all initialiser steps in Redis::Cluster.new to avoid connecting to a Redis Cluster node
        allow(::Redis::Cluster).to receive(:new).and_return(redis_cluster)
        allow(redis_cluster).to receive(:is_a?).with(::Redis::Cluster).and_return(true)
        allow(redis_cluster).to receive(:id).and_return(1)

        allow(Gitlab::Redis::MultiStore).to receive(:same_redis_store?).and_return(false)
        skip_feature_flags_yaml_validation
        skip_default_enabled_yaml_check
      end

      with_them do
        it 'returns expected value' do
          primary_store = pri_store == :cluster ? ::Redis.new(cluster: ['redis://localhost:6000']) : ::Redis.new
          secondary_store = sec_store == :cluster ? ::Redis.new(cluster: ['redis://localhost:6000']) : ::Redis.new
          multistore = Gitlab::Redis::MultiStore.new(primary_store, secondary_store, 'teststore')
          expect(described_class.cluster?(multistore)).to eq(expected_val)
        end
      end
    end

    context 'when is not Redis::Cluster' do
      it 'returns false' do
        expect(described_class.cluster?(::Redis.new)).to be_falsey
      end
    end

    context 'when is Redis::Cluster' do
      let(:redis_cluster) { instance_double(::Redis::Cluster) }

      before do
        # stub all initialiser steps in Redis::Cluster.new to avoid connecting to a Redis Cluster node
        allow(::Redis::Cluster).to receive(:new).and_return(redis_cluster)
        allow(redis_cluster).to receive(:is_a?).with(::Redis::Cluster).and_return(true)
      end

      it 'returns true' do
        expect(described_class.cluster?(::Redis.new(cluster: ['redis://localhost:6000']))).to be_truthy
      end
    end
  end
end

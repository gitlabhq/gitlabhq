# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Redis::ClusterUtil, feature_category: :scalability do
  using RSpec::Parameterized::TableSyntax

  let(:router_stub) { instance_double(::RedisClient::Cluster::Router) }
  let(:array) { Array.new(10000, &:to_s) }

  describe '.cluster?' do
    before do
      allow(::RedisClient::Cluster::Router).to receive(:new).and_return(router_stub)
    end

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
          multistore = Gitlab::Redis::MultiStore.create_using_pool(primary_pool, secondary_pool, 'teststore')

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

  shared_examples 'batches commands' do
    it 'calls pipelined multiple times' do
      Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        Gitlab::Redis::Cache.with do |c|
          expect(c).to receive(:pipelined).exactly(times).times.and_call_original

          described_class.send(cmd, Array.new(size) { |i| i }, c)
        end
      end
    end
  end

  shared_examples 'batches pipelined commands' do
    let(:times) { 1 }
    let(:size) { 1000 }

    it_behaves_like 'batches commands'

    context 'when larger than batch limit' do
      let(:times) { 2 }
      let(:size) { 1001 }

      it_behaves_like 'batches commands'
    end

    context 'when smaller than batch limit' do
      let(:times) { 1 }
      let(:size) { 999 }

      it_behaves_like 'batches commands'
    end
  end

  describe '.batch_get' do
    let(:cmd) { :batch_get }

    before do
      Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        Gitlab::Redis::Cache.with do |c|
          c.pipelined { |p| array.each { |i| p.set(i, i) } }
        end
      end
    end

    it_behaves_like 'batches pipelined commands'

    it 'gets multiple keys' do
      Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        Gitlab::Redis::Cache.with do |c|
          expect(described_class.batch_get(array, c)).to eq(array)
        end
      end
    end
  end

  describe '.batch_del' do
    let(:cmd) { :batch_del }

    before do
      Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        Gitlab::Redis::Cache.with do |c|
          c.pipelined { |p| array.each { |i| p.set(i, i) } }
        end
      end
    end

    it 'deletes multiple keys' do
      Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        Gitlab::Redis::Cache.with do |c|
          expect(described_class.batch_del(array, c)).to eq(array.size)
        end
      end
    end

    it_behaves_like 'batches pipelined commands'
  end

  describe '.batch_unlink' do
    let(:cmd) { :batch_del }

    before do
      Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        Gitlab::Redis::Cache.with do |c|
          c.pipelined { |p| array.each { |i| p.set(i, i) } }
        end
      end
    end

    it 'unlinks multiple keys' do
      Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        Gitlab::Redis::Cache.with do |c|
          expect(described_class.batch_unlink(array, c)).to eq(array.size)
        end
      end
    end

    it_behaves_like 'batches pipelined commands'
  end
end

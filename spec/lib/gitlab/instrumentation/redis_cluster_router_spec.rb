# frozen_string_literal: true

require 'spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Instrumentation::RedisClusterRouter, feature_category: :redis do
  describe '#send_command', if: ::Gitlab::Redis::Cache.params[:nodes] do
    before do
      Gitlab::Redis::Cache.with do |c|
        allow(c._client.instance_variable_get(:@router))
          .to receive(:assign_node)
          .and_raise(::RedisClient::Cluster::NodeMightBeDown)
      end
    end

    it 'tracks exception' do
      expect(Gitlab::ErrorTracking)
        .to receive(:log_exception).with(
          instance_of(::RedisClient::Cluster::NodeMightBeDown), node_keys: anything, slots_map: anything
        )

      expect(Gitlab::Instrumentation::Redis::Cache)
        .to receive(:instance_count_exception).with(instance_of(::RedisClient::Cluster::NodeMightBeDown))

      expect do
        Gitlab::Redis::Cache.with { |c| c.decr('test') }
      end.to raise_error(Redis::Cluster::NodeMightBeDown) # redis-rb gem intercepts and replaces error
    end
  end

  describe '.format_slotmap' do
    it 'handles empty slot array' do
      expect(described_class.format_slotmap([])).to eq({})
    end

    it 'handles incomplete slot array' do
      input = ['localhost:1', 'localhost:1', nil, 'localhost:2']
      expect(described_class.format_slotmap(input)).to eq({ 'localhost:1' => '0-1', 'localhost:2' => '3-3' })
    end

    it 'handles complete slot array' do
      input = (['localhost:1'] * 5000) + (['localhost:2'] * 5000) + (['localhost:3'] * 5000) + (['localhost:1'] * 5000)
      expect(described_class.format_slotmap(input))
        .to eq({
          'localhost:1' => '0-4999,15000-16383', 'localhost:2' => '5000-9999', 'localhost:3' => '10000-14999'
        })
    end
  end

  describe '.compact_array' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :output) do
      [1, 2, 3, 4, 5, 6, 7] | "1-7" # contiguous
      [1, 2, 3, 5, 6, 7, 9, 10] | "1-3,5-7,9-10" # non-contiguous
      [1, 2, 3, 4, 5, 7] | "1-5,7-7" # contigious with 1 ending slot
      [] | "" # empty
      [1, 1, 1, 1] | "1-1" # homogenuous array
    end

    with_them do
      it do
        expect(described_class.compact_array(input)).to eq(output)
      end
    end
  end
end

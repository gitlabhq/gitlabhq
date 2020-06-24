# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Instrumentation::Redis do
  def stub_storages(method, value)
    described_class::STORAGES.each do |storage|
      allow(storage).to receive(method) { value }
    end
  end

  shared_examples 'aggregation of redis storage data' do |method|
    describe "#{method} sum" do
      it "sums data from all Redis storages" do
        amount = 0.3

        stub_storages(method, amount)

        expect(described_class.public_send(method)).to eq(described_class::STORAGES.size * amount)
      end
    end
  end

  it_behaves_like 'aggregation of redis storage data', :get_request_count
  it_behaves_like 'aggregation of redis storage data', :query_time
  it_behaves_like 'aggregation of redis storage data', :read_bytes
  it_behaves_like 'aggregation of redis storage data', :write_bytes

  describe '.known_payload_keys' do
    it 'returns all known payload keys' do
      expected_keys = [
        :redis_calls,
        :redis_duration_s,
        :redis_read_bytes,
        :redis_write_bytes,
        :redis_action_cable_calls,
        :redis_action_cable_duration_s,
        :redis_action_cable_read_bytes,
        :redis_action_cable_write_bytes,
        :redis_cache_calls,
        :redis_cache_duration_s,
        :redis_cache_read_bytes,
        :redis_cache_write_bytes,
        :redis_queues_calls,
        :redis_queues_duration_s,
        :redis_queues_read_bytes,
        :redis_queues_write_bytes,
        :redis_shared_state_calls,
        :redis_shared_state_duration_s,
        :redis_shared_state_read_bytes,
        :redis_shared_state_write_bytes
      ]

      expect(described_class.known_payload_keys).to eq(expected_keys)
    end

    it 'does not call storage calculation methods' do
      described_class::STORAGES.each do |storage|
        expect(storage).not_to receive(:get_request_count)
        expect(storage).not_to receive(:query_time)
        expect(storage).not_to receive(:read_bytes)
        expect(storage).not_to receive(:write_bytes)
      end

      described_class.known_payload_keys
    end
  end

  describe '.payload', :request_store do
    before do
      Gitlab::Redis::Cache.with { |redis| redis.set('cache-test', 321) }
      Gitlab::Redis::SharedState.with { |redis| redis.set('shared-state-test', 123) }
    end

    it 'returns payload filtering out zeroed values' do
      expected_payload = {
        # Aggregated results
        redis_calls: 2,
        redis_duration_s: be >= 0,
        redis_read_bytes: be >= 0,
        redis_write_bytes: be >= 0,

        # Cache results
        redis_cache_calls: 1,
        redis_cache_duration_s: be >= 0,
        redis_cache_read_bytes: be >= 0,
        redis_cache_write_bytes: be >= 0,

        # Shared state results
        redis_shared_state_calls: 1,
        redis_shared_state_duration_s: be >= 0,
        redis_shared_state_read_bytes: be >= 0,
        redis_shared_state_write_bytes: be >= 0
      }

      expect(described_class.payload).to include(expected_payload)
      expect(described_class.payload.keys).to match_array(expected_payload.keys)
    end
  end

  describe '.detail_store' do
    it 'returns a flat array of detail stores with the storage name added to each item' do
      details_row = { cmd: 'GET foo', duration: 1 }

      stub_storages(:detail_store, [details_row])

      expect(described_class.detail_store)
        .to contain_exactly(details_row.merge(storage: 'ActionCable'),
                            details_row.merge(storage: 'Cache'),
                            details_row.merge(storage: 'Queues'),
                            details_row.merge(storage: 'SharedState'))
    end
  end
end

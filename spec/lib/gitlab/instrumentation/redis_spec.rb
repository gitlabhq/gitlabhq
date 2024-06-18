# frozen_string_literal: true

require 'spec_helper'
require 'support/helpers/rails_helpers'

RSpec.describe Gitlab::Instrumentation::Redis do
  include RedisHelpers

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
  it_behaves_like 'aggregation of redis storage data', :get_cross_slot_request_count
  it_behaves_like 'aggregation of redis storage data', :get_allowed_cross_slot_request_count
  it_behaves_like 'aggregation of redis storage data', :query_time
  it_behaves_like 'aggregation of redis storage data', :read_bytes
  it_behaves_like 'aggregation of redis storage data', :write_bytes

  describe '.payload', :request_store do
    let_it_be(:redis_store_class) { define_helper_redis_store_class }

    before do
      # If this is the first spec in a spec run that uses Redis, there
      # will be an extra SELECT command to choose the right database. We
      # don't want to make the spec less precise, so we force that to
      # happen (if needed) first, then clear the counts.
      redis_store_class.with { |redis| redis.info }
      RequestStore.clear!

      stub_rails_env('staging') # to avoid raising CrossSlotError
      redis_store_class.with { |redis| redis.mset('cache-test', 321, 'cache-test-2', 321) }
      Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
        redis_store_class.with { |redis| redis.mget('cache-test', 'cache-test-2') }
      end
      Gitlab::Redis::Queues.with { |redis| redis.set('shared-state-test', 123) }
    end

    it 'returns payload filtering out zeroed values',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/446221' do
      expected_payload = {
        # Aggregated results
        redis_calls: 3,
        redis_cross_slot_calls: 1,
        redis_allowed_cross_slot_calls: 1,
        redis_duration_s: be >= 0,
        redis_read_bytes: be >= 0,
        redis_write_bytes: be >= 0,

        # Queues results
        redis_sessions_calls: 2,
        redis_sessions_cross_slot_calls: 1,
        redis_sessions_allowed_cross_slot_calls: 1,
        redis_sessions_duration_s: be >= 0,
        redis_sessions_read_bytes: be >= 0,
        redis_sessions_write_bytes: be >= 0,

        # Queues results
        redis_queues_calls: 1,
        redis_queues_duration_s: be >= 0,
        redis_queues_read_bytes: be >= 0,
        redis_queues_write_bytes: be >= 0
      }

      expect(described_class.payload).to include(expected_payload)
      expect(described_class.payload.keys).to match_array(expected_payload.keys)
    end
  end

  describe '.detail_store' do
    it 'returns a flat array of detail stores with the storage name added to each item' do
      details_row = { cmd: 'GET foo', duration: 1 }

      stub_storages(:detail_store, [details_row])

      expected_detail_stores = Gitlab::Redis::ALL_CLASSES.map(&:store_name)
                                 .map { |store_name| details_row.merge(storage: store_name) }
      expected_detail_stores << details_row.merge(storage: 'ActionCable')
      expect(described_class.detail_store).to contain_exactly(*expected_detail_stores)
    end
  end
end

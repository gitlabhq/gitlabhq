# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::WriteBuffer, :clean_gitlab_redis_shared_state, feature_category: :database do
  let(:table_name) { 'test' }

  describe '.add' do
    subject(:add_event) { described_class.add(table_name, event_hash) }

    let(:event_hash) { { foo: 'bar' } }

    it 'saves ClickHouse event to Redis' do
      expect do
        add_event
      end.to change {
        Gitlab::Redis::SharedState.with do |redis|
          redis.lrange(described_class::BUFFER_KEY_PREFIX + table_name, 0, 10)
        end
      }.from([]).to([event_hash.to_json])
    end
  end

  describe '.pop_events' do
    let(:limit) { 2 }

    let(:event1) { { foo: 'bar' } }
    let(:event2) { { foo: 'bar2' } }
    let(:event3) { { foo: 'bar3' } }

    before do
      described_class.add(table_name, event1)
      described_class.add(table_name, event2)
      described_class.add(table_name, event3)
    end

    it 'pops events from redis' do
      expect(described_class.pop(table_name, limit)).to eq([event1, event2])
      expect(described_class.pop(table_name, limit)).to eq([event3])
      expect(described_class.pop(table_name, limit)).to eq([])
    end
  end

  it_behaves_like 'using redis backwards compatible methods' do
    let(:buffer_key) { 'clickhouse_write_buffer_test_model' }
  end
end

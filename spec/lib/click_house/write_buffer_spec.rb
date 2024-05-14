# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ClickHouse::WriteBuffer, :clean_gitlab_redis_shared_state, feature_category: :database do
  describe '.write_event' do
    subject(:write_event) { described_class.write_event(event_hash) }

    let(:event_hash) { { foo: 'bar' } }

    it 'saves ClickHouse event to Redis' do
      expect do
        write_event
      end.to change {
        Gitlab::Redis::SharedState.with do |redis|
          redis.lrange(described_class::BUFFER_KEY, 0, 10)
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
      described_class.write_event(event1)
      described_class.write_event(event2)
      described_class.write_event(event3)
    end

    it 'pops events from redis' do
      expect(described_class.pop_events(limit)).to eq([event1, event2])
      expect(described_class.pop_events(limit)).to eq([event3])
      expect(described_class.pop_events(limit)).to eq([])
    end
  end
end

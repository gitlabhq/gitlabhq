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
end

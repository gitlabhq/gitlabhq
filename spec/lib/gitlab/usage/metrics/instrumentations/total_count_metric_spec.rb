# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::TotalCountMetric, :clean_gitlab_redis_shared_state,
  feature_category: :product_analytics_data_management do
  before do
    allow(Gitlab::InternalEvents::EventDefinitions).to receive(:known_event?).and_return(true)
  end

  context 'with multiple similar events' do
    let(:expected_value) { 10 }

    before do
      10.times do
        Gitlab::InternalEvents.track_event('my_event')
      end
    end

    it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', events: [{ name: 'my_event' }] }
  end

  context 'with multiple different events' do
    let(:expected_value) { 2 }

    before do
      Gitlab::InternalEvents.track_event('my_event1')
      Gitlab::InternalEvents.track_event('my_event2')
    end

    it_behaves_like 'a correct instrumented metric value',
      { time_frame: 'all', events: [{ name: 'my_event1' }, { name: 'my_event2' }] }
  end

  describe '.redis_key' do
    it 'adds the key prefix to the event name' do
      expect(described_class.redis_key('my_event')).to eq('{event_counters}_my_event')
    end
  end
end

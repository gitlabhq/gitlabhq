# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::TotalCountMetric, :clean_gitlab_redis_shared_state,
  feature_category: :product_analytics_data_management do
  before do
    allow(Gitlab::InternalEvents::EventDefinitions).to receive(:known_event?).and_return(true)
  end

  context 'with multiple similar events' do
    before do
      last_week = Date.today - 7.days
      two_weeks_ago = last_week - 1.week

      redis_counter_key = described_class.redis_key('my_event', last_week)
      2.times do
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      redis_counter_key = described_class.redis_key('my_event', two_weeks_ago)
      3.times do
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      10.times do
        Gitlab::InternalEvents.track_event('my_event')
      end
    end

    context "with an 'all' time_frame" do
      let(:expected_value) { 10 }

      it_behaves_like 'a correct instrumented metric value', { time_frame: 'all', events: [{ name: 'my_event' }] }
    end

    context "with a 7d time_frame" do
      let(:expected_value) { 2 }

      it_behaves_like 'a correct instrumented metric value', { time_frame: '7d', events: [{ name: 'my_event' }] }
    end

    context "with a 28d time_frame" do
      let(:expected_value) { 5 }

      it_behaves_like 'a correct instrumented metric value', { time_frame: '28d', events: [{ name: 'my_event' }] }
    end
  end

  context 'with multiple different events' do
    let(:expected_value) { 2 }

    before do
      last_week = Date.today - 7.days
      two_weeks_ago = last_week - 1.week

      2.times do
        redis_counter_key =
          Gitlab::Usage::Metrics::Instrumentations::TotalCountMetric.redis_key('my_event1', last_week)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      3.times do
        redis_counter_key =
          Gitlab::Usage::Metrics::Instrumentations::TotalCountMetric.redis_key('my_event1', two_weeks_ago)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      4.times do
        redis_counter_key =
          Gitlab::Usage::Metrics::Instrumentations::TotalCountMetric.redis_key('my_event2', last_week)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      Gitlab::InternalEvents.track_event('my_event1')
      Gitlab::InternalEvents.track_event('my_event2')
    end

    context "with an 'all' time_frame" do
      let(:expected_value) { 2 }

      it_behaves_like 'a correct instrumented metric value',
        { time_frame: 'all', events: [{ name: 'my_event1' }, { name: 'my_event2' }] }
    end

    context "with a 7d time_frame" do
      let(:expected_value) { 6 }

      it_behaves_like 'a correct instrumented metric value',
        { time_frame: '7d', events: [{ name: 'my_event1' }, { name: 'my_event2' }] }
    end

    context "with a 28d time_frame" do
      let(:expected_value) { 9 }

      it_behaves_like 'a correct instrumented metric value',
        { time_frame: '28d', events: [{ name: 'my_event1' }, { name: 'my_event2' }] }
    end
  end

  context "with an invalid time_frame" do
    let(:metric) { described_class.new(time_frame: '14d', events: [{ name: 'my_event' }]) }

    it 'raises an exception' do
      expect { metric.value }.to raise_error(/Unknown time frame/)
    end
  end

  describe '.redis_key' do
    it 'adds the key prefix to the event name' do
      expect(described_class.redis_key('my_event')).to eq('{event_counters}_my_event')
    end

    context "with a date" do
      it 'adds the key prefix and suffix to the event name' do
        expect(described_class.redis_key('my_event', Date.new(2023, 10, 19))).to eq("{event_counters}_my_event-2023-42")
      end
    end
  end
end

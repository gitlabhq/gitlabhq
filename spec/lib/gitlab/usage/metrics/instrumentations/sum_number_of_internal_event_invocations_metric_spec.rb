# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::SumNumberOfInternalEventInvocationsMetric,
  :clean_gitlab_redis_shared_state, feature_category: :product_analytics do
  before do
    event_definition1 = instance_double(
      Gitlab::Tracking::EventDefinition,
      action: 'internal_event1',
      internal_events?: true
    )

    event_definition2 = instance_double(
      Gitlab::Tracking::EventDefinition,
      action: 'internal_event2',
      internal_events?: true
    )

    # Non-internal event that should be excluded
    event_definition3 = instance_double(
      Gitlab::Tracking::EventDefinition,
      action: 'non_internal_event',
      internal_events?: false
    )

    definitions = [event_definition1, event_definition2, event_definition3]
    allow(Gitlab::Tracking::EventDefinition)
      .to receive_messages(internal_event_exists?: true, definitions: definitions)
  end

  context 'with multiple internal events' do
    let(:event_selection_rule1) { Gitlab::Usage::EventSelectionRule.new(name: 'internal_event1', time_framed: true) }
    let(:event_selection_rule2) { Gitlab::Usage::EventSelectionRule.new(name: 'internal_event2', time_framed: true) }

    before do
      last_week = Time.zone.today - 7.days
      two_weeks_ago = last_week - 1.week

      # Create Redis data for internal_event1
      2.times do
        redis_counter_key = event_selection_rule1.redis_key_for_date(last_week)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      3.times do
        redis_counter_key = event_selection_rule1.redis_key_for_date(two_weeks_ago)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      # Create Redis data for internal_event2
      4.times do
        redis_counter_key = event_selection_rule2.redis_key_for_date(last_week)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      5.times do
        redis_counter_key = event_selection_rule2.redis_key_for_date(two_weeks_ago)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      # Create Redis data for non-internal event (should be ignored)
      non_internal_event_rule = Gitlab::Usage::EventSelectionRule.new(name: 'non_internal_event', time_framed: true)
      8.times do
        redis_counter_key = non_internal_event_rule.redis_key_for_date(last_week)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end
    end

    context "with a '7d' time_frame" do
      let(:expected_value) { 6 } # 2 from event1 + 4 from event2

      it_behaves_like 'a correct instrumented metric value', { time_frame: '7d' }
    end

    context "with a '28d' time_frame" do
      let(:expected_value) { 14 } # 5 from event1 + 9 from event2

      it_behaves_like 'a correct instrumented metric value', { time_frame: '28d' }
    end
  end

  context "with an invalid time_frame" do
    let(:metric) { described_class.new(time_frame: '14d') }

    it 'raises an exception' do
      expect { metric.value }.to raise_error(/Unknown time frame/)
    end
  end

  context "with no internal events" do
    before do
      allow(Gitlab::Tracking::EventDefinition).to receive(:definitions).and_return([])
    end

    context "with a '7d' time_frame" do
      let(:expected_value) { 0 }

      it_behaves_like 'a correct instrumented metric value', { time_frame: '7d' }
    end
  end
end

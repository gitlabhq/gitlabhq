# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::TotalCountMetric, :clean_gitlab_redis_shared_state,
  feature_category: :product_analytics do
  before do
    allow(Gitlab::Tracking::EventDefinition).to receive(:internal_event_exists?).and_return(true)

    event_definition = instance_double(
      Gitlab::Tracking::EventDefinition,
      event_selection_rules: [Gitlab::Usage::EventSelectionRule.new(name: 'my_event', time_framed: false)],
      additional_properties: {}
    )
    allow(Gitlab::Tracking::EventDefinition).to receive(:find).with('my_event').and_return(event_definition)

    event_definition1 = instance_double(
      Gitlab::Tracking::EventDefinition,
      event_selection_rules: [Gitlab::Usage::EventSelectionRule.new(name: 'my_event1', time_framed: false)],
      additional_properties: {}
    )
    allow(Gitlab::Tracking::EventDefinition).to receive(:find).with('my_event1').and_return(event_definition1)

    event_definition2 = instance_double(
      Gitlab::Tracking::EventDefinition,
      event_selection_rules: [Gitlab::Usage::EventSelectionRule.new(name: 'my_event2', time_framed: false)],
      additional_properties: {}
    )
    allow(Gitlab::Tracking::EventDefinition).to receive(:find).with('my_event2').and_return(event_definition2)

    allow(event_definition).to receive(:extra_tracking_classes).and_return([])
    allow(event_definition1).to receive(:extra_tracking_classes).and_return([])
    allow(event_definition2).to receive(:extra_tracking_classes).and_return([])
  end

  context 'with multiple similar events' do
    let(:event_selection_rule) { Gitlab::Usage::EventSelectionRule.new(name: 'my_event', time_framed: true) }

    before do
      last_week = Date.today - 7.days
      two_weeks_ago = last_week - 1.week

      redis_counter_key = event_selection_rule.redis_key_for_date(last_week)
      2.times do
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      redis_counter_key = event_selection_rule.redis_key_for_date(two_weeks_ago)
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
    let(:event_selection_rule1) { Gitlab::Usage::EventSelectionRule.new(name: 'my_event1', time_framed: true) }
    let(:event_selection_rule2) { Gitlab::Usage::EventSelectionRule.new(name: 'my_event2', time_framed: true) }

    before do
      last_week = Date.today - 7.days
      two_weeks_ago = last_week - 1.week

      2.times do
        redis_counter_key = event_selection_rule1.redis_key_for_date(last_week)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      3.times do
        redis_counter_key = event_selection_rule1.redis_key_for_date(two_weeks_ago)
        Gitlab::Redis::SharedState.with { |redis| redis.incr(redis_counter_key) }
      end

      4.times do
        redis_counter_key = event_selection_rule2.redis_key_for_date(last_week)
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
end

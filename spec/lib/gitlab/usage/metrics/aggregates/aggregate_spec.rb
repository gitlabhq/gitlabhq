# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Aggregates::Aggregate, :clean_gitlab_redis_shared_state do
  let(:entity1) { 'dfb9d2d2-f56c-4c77-8aeb-6cddc4a1f857' }
  let(:entity2) { '1dd9afb2-a3ee-4de1-8ae3-a405579c8584' }
  let(:entity3) { '34rfjuuy-ce56-sa35-ds34-dfer567dfrf2' }
  let(:entity4) { '8b9a2671-2abf-4bec-a682-22f6a8f7bf31' }

  around do |example|
    # We need to freeze to a reference time
    # because visits are grouped by the week number in the year
    # Without freezing the time, the test may behave inconsistently
    # depending on which day of the week test is run.
    # Monday 6th of June
    reference_time = Time.utc(2020, 6, 1)
    travel_to(reference_time) { example.run }
  end

  context 'aggregated_metrics_data' do
    let(:known_events) do
      [
        { name: 'event1_slot', redis_slot: "slot", category: 'category1', aggregation: "weekly" },
        { name: 'event2_slot', redis_slot: "slot", category: 'category2', aggregation: "weekly" },
        { name: 'event3_slot', redis_slot: "slot", category: 'category3', aggregation: "weekly" },
        { name: 'event5_slot', redis_slot: "slot", category: 'category4', aggregation: "weekly" },
        { name: 'event4', category: 'category2', aggregation: "weekly" }
      ].map(&:with_indifferent_access)
    end

    before do
      allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_events).and_return(known_events)
    end

    shared_examples 'aggregated_metrics_data' do
      context 'no aggregated metrics is defined' do
        it 'returns empty hash' do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:aggregated_metrics).and_return([])
          end

          expect(aggregated_metrics_data).to eq({})
        end
      end

      context 'there are aggregated metrics defined' do
        before do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:aggregated_metrics).and_return(aggregated_metrics)
          end
        end

        context 'with AND operator' do
          let(:aggregated_metrics) do
            [
              { name: 'gmau_1', events: %w[event1_slot event2_slot], operator: "AND" },
              { name: 'gmau_2', events: %w[event1_slot event2_slot event3_slot], operator: "AND" },
              { name: 'gmau_3', events: %w[event1_slot event2_slot event3_slot event5_slot], operator: "AND" },
              { name: 'gmau_4', events: %w[event4], operator: "AND" }
            ].map(&:with_indifferent_access)
          end

          it 'returns the number of unique events for all known events' do
            results = {
              'gmau_1' => 3,
              'gmau_2' => 2,
              'gmau_3' => 1,
              'gmau_4' => 3
            }

            expect(aggregated_metrics_data).to eq(results)
          end
        end

        context 'with OR operator' do
          let(:aggregated_metrics) do
            [
              { name: 'gmau_1', events: %w[event3_slot event5_slot], operator: "OR" },
              { name: 'gmau_2', events: %w[event1_slot event2_slot event3_slot event5_slot], operator: "OR" },
              { name: 'gmau_3', events: %w[event4], operator: "OR" }
            ].map(&:with_indifferent_access)
          end

          it 'returns the number of unique events for all known events' do
            results = {
              'gmau_1' => 2,
              'gmau_2' => 3,
              'gmau_3' => 3
            }

            expect(aggregated_metrics_data).to eq(results)
          end
        end

        context 'hidden behind feature flag' do
          let(:enabled_feature_flag) { 'test_ff_enabled' }
          let(:disabled_feature_flag) { 'test_ff_disabled' }
          let(:aggregated_metrics) do
            [
              # represents stable aggregated metrics that has been fully released
              { name: 'gmau_without_ff', events: %w[event3_slot event5_slot], operator: "OR" },
              # represents new aggregated metric that is under performance testing on gitlab.com
              { name: 'gmau_enabled', events: %w[event4], operator: "AND", feature_flag: enabled_feature_flag },
              # represents aggregated metric that is under development and shouldn't be yet collected even on gitlab.com
              { name: 'gmau_disabled', events: %w[event4], operator: "AND", feature_flag: disabled_feature_flag }
            ].map(&:with_indifferent_access)
          end

          it 'returns the number of unique events for all known events' do
            skip_feature_flags_yaml_validation
            stub_feature_flags(enabled_feature_flag => true, disabled_feature_flag => false)

            expect(aggregated_metrics_data).to eq('gmau_without_ff' => 2, 'gmau_enabled' => 3)
          end
        end
      end

      context 'error handling' do
        context 'development and test environment' do
          it 'raises error when unknown aggregation operator is used' do
            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:aggregated_metrics)
                                   .and_return([{ name: 'gmau_1', events: %w[event1_slot], operator: "SUM" }])
            end

            expect { aggregated_metrics_data }.to raise_error Gitlab::Usage::Metrics::Aggregates::UnknownAggregationOperator
          end

          it 're raises Gitlab::UsageDataCounters::HLLRedisCounter::EventError' do
            error = Gitlab::UsageDataCounters::HLLRedisCounter::EventError
            allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:calculate_events_union).and_raise(error)

            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:aggregated_metrics)
                                   .and_return([{ name: 'gmau_1', events: %w[event1_slot], operator: "OR" }])
            end

            expect { aggregated_metrics_data }.to raise_error error
          end
        end

        context 'production' do
          before do
            stub_rails_env('production')
          end

          it 'rescues unknown aggregation operator error' do
            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:aggregated_metrics)
                                   .and_return([{ name: 'gmau_1', events: %w[event1_slot], operator: "SUM" }])
            end

            expect(aggregated_metrics_data).to eq('gmau_1' => -1)
          end

          it 'rescues Gitlab::UsageDataCounters::HLLRedisCounter::EventError' do
            error = Gitlab::UsageDataCounters::HLLRedisCounter::EventError
            allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:calculate_events_union).and_raise(error)

            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:aggregated_metrics)
                                   .and_return([{ name: 'gmau_1', events: %w[event1_slot], operator: "OR" }])
            end

            expect(aggregated_metrics_data).to eq('gmau_1' => -1)
          end
        end
      end
    end

    describe '.aggregated_metrics_weekly_data' do
      subject(:aggregated_metrics_data) { described_class.new.weekly_data }

      before do
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event1_slot', values: entity1, time: 2.days.ago)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event1_slot', values: entity2, time: 2.days.ago)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event1_slot', values: entity3, time: 2.days.ago)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event2_slot', values: entity1, time: 2.days.ago)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event2_slot', values: entity2, time: 3.days.ago)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event2_slot', values: entity3, time: 3.days.ago)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event3_slot', values: entity1, time: 3.days.ago)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event3_slot', values: entity2, time: 3.days.ago)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event5_slot', values: entity2, time: 3.days.ago)

        # events out of time scope
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event2_slot', values: entity3, time: 8.days.ago)

        # events in different slots
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event4', values: entity1, time: 2.days.ago)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event4', values: entity2, time: 2.days.ago)
        Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event4', values: entity4, time: 2.days.ago)
      end

      it_behaves_like 'aggregated_metrics_data'
    end

    describe '.aggregated_metrics_monthly_data' do
      subject(:aggregated_metrics_data) { described_class.new.monthly_data }

      it_behaves_like 'aggregated_metrics_data' do
        before do
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event1_slot', values: entity1, time: 2.days.ago)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event1_slot', values: entity2, time: 2.days.ago)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event1_slot', values: entity3, time: 2.days.ago)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event2_slot', values: entity1, time: 2.days.ago)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event2_slot', values: entity2, time: 3.days.ago)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event2_slot', values: entity3, time: 3.days.ago)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event3_slot', values: entity1, time: 3.days.ago)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event3_slot', values: entity2, time: 10.days.ago)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event5_slot', values: entity2, time: 4.weeks.ago.advance(days: 1))

          # events out of time scope
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event5_slot', values: entity1, time: 4.weeks.ago.advance(days: -1))

          # events in different slots
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event4', values: entity1, time: 2.days.ago)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event4', values: entity2, time: 2.days.ago)
          Gitlab::UsageDataCounters::HLLRedisCounter.track_event('event4', values: entity4, time: 2.days.ago)
        end
      end

      context 'Redis calls' do
        let(:aggregated_metrics) do
          [
            { name: 'gmau_3', events: %w[event1_slot event2_slot event3_slot event5_slot], operator: "AND" }
          ].map(&:with_indifferent_access)
        end

        it 'caches intermediate operations' do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:aggregated_metrics).and_return(aggregated_metrics)
          end

          aggregated_metrics[0][:events].each do |event|
            expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:calculate_events_union)
                                                                    .with(event_names: event, start_date: 4.weeks.ago.to_date, end_date: Date.current)
                                                                    .once
                                                                    .and_return(0)
          end

          2.upto(4) do |subset_size|
            aggregated_metrics[0][:events].combination(subset_size).each do |events|
              expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:calculate_events_union)
                                                                      .with(event_names: events, start_date: 4.weeks.ago.to_date, end_date: Date.current)
                                                                      .once
                                                                      .and_return(0)
            end
          end

          aggregated_metrics_data
        end
      end
    end
  end
end

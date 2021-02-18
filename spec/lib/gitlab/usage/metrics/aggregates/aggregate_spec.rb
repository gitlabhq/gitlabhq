# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Aggregates::Aggregate, :clean_gitlab_redis_shared_state do
  let(:entity1) { 'dfb9d2d2-f56c-4c77-8aeb-6cddc4a1f857' }
  let(:entity2) { '1dd9afb2-a3ee-4de1-8ae3-a405579c8584' }
  let(:entity3) { '34rfjuuy-ce56-sa35-ds34-dfer567dfrf2' }
  let(:entity4) { '8b9a2671-2abf-4bec-a682-22f6a8f7bf31' }
  let(:end_date) { Date.current }
  let(:sources) { Gitlab::Usage::Metrics::Aggregates::Sources }

  let_it_be(:recorded_at) { Time.current.to_i }

  context 'aggregated_metrics_data' do
    shared_examples 'aggregated_metrics_data' do
      context 'no aggregated metric is defined' do
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

        context 'with disabled database_sourced_aggregated_metrics feature flag' do
          before do
            stub_feature_flags(database_sourced_aggregated_metrics: false)
          end

          let(:aggregated_metrics) do
            [
              { name: 'gmau_1', source: 'redis', events: %w[event3 event5], operator: "OR" },
              { name: 'gmau_2', source: 'database', events: %w[event1 event2 event3], operator: "OR" }
            ].map(&:with_indifferent_access)
          end

          it 'skips database sourced metrics', :aggregate_failures do
            results = {
              'gmau_1' => 5
            }

            params = { start_date: start_date, end_date: end_date, recorded_at: recorded_at }

            expect(sources::RedisHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event3 event5])).and_return(5)
            expect(sources::PostgresHll).not_to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event1 event2 event3]))
            expect(aggregated_metrics_data).to eq(results)
          end
        end

        context 'with AND operator' do
          let(:aggregated_metrics) do
            [
              { name: 'gmau_1', source: 'redis', events: %w[event3 event5], operator: "AND" },
              { name: 'gmau_2', source: 'database', events: %w[event1 event2 event3], operator: "AND" }
            ].map(&:with_indifferent_access)
          end

          it 'returns the number of unique events recorded for every metric in aggregate', :aggregate_failures do
            results = {
              'gmau_1' => 2,
              'gmau_2' => 1
            }
            params = { start_date: start_date, end_date: end_date, recorded_at: recorded_at }

            # gmau_1 data is as follow
            # |A| => 4
            expect(sources::RedisHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: 'event3')).and_return(4)
            # |B| => 6
            expect(sources::RedisHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: 'event5')).and_return(6)
            # |A + B| => 8
            expect(sources::RedisHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event3 event5])).and_return(8)
            # Exclusion inclusion principle formula to calculate intersection of 2 sets
            # |A & B| = (|A| + |B|) - |A + B| => (4 + 6) - 8 => 2

            # gmau_2 data is as follow:
            # |A| => 2
            expect(sources::PostgresHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: 'event1')).and_return(2)
            # |B| => 3
            expect(sources::PostgresHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: 'event2')).and_return(3)
            # |C| => 5
            expect(sources::PostgresHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: 'event3')).and_return(5)

            # |A + B| => 4 therefore |A & B| = (|A| + |B|) - |A + B| =>  2 + 3 - 4 => 1
            expect(sources::PostgresHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event1 event2])).and_return(4)
            # |A + C| => 6 therefore |A & C| = (|A| + |C|) - |A + C| =>  2 + 5 - 6  => 1
            expect(sources::PostgresHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event1 event3])).and_return(6)
            # |B + C| => 7 therefore |B & C| = (|B| + |C|) - |B + C| => 3 + 5 - 7 => 1
            expect(sources::PostgresHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event2 event3])).and_return(7)
            # |A + B + C| => 8
            expect(sources::PostgresHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event1 event2 event3])).and_return(8)
            # Exclusion inclusion principle formula to calculate intersection of 3 sets
            # |A & B & C| = (|A & B| + |A & C| + |B & C|) - (|A| + |B| + |C|)  + |A + B + C|
            # (1 + 1 + 1) - (2 + 3 + 5) + 8 => 1

            expect(aggregated_metrics_data).to eq(results)
          end
        end

        context 'with OR operator' do
          let(:aggregated_metrics) do
            [
              { name: 'gmau_1', source: 'redis', events: %w[event3 event5], operator: "OR" },
              { name: 'gmau_2', source: 'database', events: %w[event1 event2 event3], operator: "OR" }
            ].map(&:with_indifferent_access)
          end

          it 'returns the number of unique events occurred for any metric in aggregate', :aggregate_failures do
            results = {
              'gmau_1' => 5,
              'gmau_2' => 3
            }
            params = { start_date: start_date, end_date: end_date, recorded_at: recorded_at }

            expect(sources::RedisHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event3 event5])).and_return(5)
            expect(sources::PostgresHll).to receive(:calculate_metrics_union).with(params.merge(metric_names: %w[event1 event2 event3])).and_return(3)
            expect(aggregated_metrics_data).to eq(results)
          end
        end

        context 'hidden behind feature flag' do
          let(:enabled_feature_flag) { 'test_ff_enabled' }
          let(:disabled_feature_flag) { 'test_ff_disabled' }
          let(:aggregated_metrics) do
            [
              # represents stable aggregated metrics that has been fully released
              { name: 'gmau_without_ff', source: 'redis', events: %w[event3_slot event5_slot], operator: "OR" },
              # represents new aggregated metric that is under performance testing on gitlab.com
              { name: 'gmau_enabled', source: 'redis', events: %w[event4], operator: "OR", feature_flag: enabled_feature_flag },
              # represents aggregated metric that is under development and shouldn't be yet collected even on gitlab.com
              { name: 'gmau_disabled', source: 'redis', events: %w[event4], operator: "OR", feature_flag: disabled_feature_flag }
            ].map(&:with_indifferent_access)
          end

          it 'does not calculate data for aggregates with ff turned off' do
            skip_feature_flags_yaml_validation
            skip_default_enabled_yaml_check
            stub_feature_flags(enabled_feature_flag => true, disabled_feature_flag => false)
            allow(sources::RedisHll).to receive(:calculate_metrics_union).and_return(6)

            expect(aggregated_metrics_data).to eq('gmau_without_ff' => 6, 'gmau_enabled' => 6)
          end
        end
      end

      context 'error handling' do
        context 'development and test environment' do
          it 'raises error when unknown aggregation operator is used' do
            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:aggregated_metrics)
                                   .and_return([{ name: 'gmau_1', source: 'redis', events: %w[event1_slot], operator: "SUM" }])
            end

            expect { aggregated_metrics_data }.to raise_error Gitlab::Usage::Metrics::Aggregates::UnknownAggregationOperator
          end

          it 'raises error when unknown aggregation source is used' do
            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:aggregated_metrics)
                                   .and_return([{ name: 'gmau_1', source: 'whoami', events: %w[event1_slot], operator: "AND" }])
            end

            expect { aggregated_metrics_data }.to raise_error Gitlab::Usage::Metrics::Aggregates::UnknownAggregationSource
          end

          it 're raises Gitlab::UsageDataCounters::HLLRedisCounter::EventError' do
            error = Gitlab::UsageDataCounters::HLLRedisCounter::EventError
            allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:calculate_events_union).and_raise(error)

            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:aggregated_metrics)
                                   .and_return([{ name: 'gmau_1', source: 'redis', events: %w[event1_slot], operator: "OR" }])
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
                                   .and_return([{ name: 'gmau_1', source: 'redis', events: %w[event1_slot], operator: "SUM" }])
            end

            expect(aggregated_metrics_data).to eq('gmau_1' => -1)
          end

          it 'rescues unknown aggregation source error' do
            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:aggregated_metrics)
                                   .and_return([{ name: 'gmau_1', source: 'whoami', events: %w[event1_slot], operator: "AND" }])
            end

            expect(aggregated_metrics_data).to eq('gmau_1' => -1)
          end

          it 'rescues Gitlab::UsageDataCounters::HLLRedisCounter::EventError' do
            error = Gitlab::UsageDataCounters::HLLRedisCounter::EventError
            allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:calculate_events_union).and_raise(error)

            allow_next_instance_of(described_class) do |instance|
              allow(instance).to receive(:aggregated_metrics)
                                   .and_return([{ name: 'gmau_1', source: 'redis', events: %w[event1_slot], operator: "OR" }])
            end

            expect(aggregated_metrics_data).to eq('gmau_1' => -1)
          end
        end
      end
    end

    it 'allows for YAML aliases in aggregated metrics configs' do
      expect(YAML).to receive(:safe_load).with(kind_of(String), aliases: true).at_least(:once)

      described_class.new(recorded_at)
    end

    describe '.aggregated_metrics_weekly_data' do
      subject(:aggregated_metrics_data) { described_class.new(recorded_at).weekly_data }

      let(:start_date) { 7.days.ago.to_date }

      it_behaves_like 'aggregated_metrics_data'
    end

    describe '.aggregated_metrics_monthly_data' do
      subject(:aggregated_metrics_data) { described_class.new(recorded_at).monthly_data }

      let(:start_date) { 4.weeks.ago.to_date }

      it_behaves_like 'aggregated_metrics_data'

      context 'metrics union calls' do
        let(:aggregated_metrics) do
          [
            { name: 'gmau_3', source: 'redis', events: %w[event1_slot event2_slot event3_slot event5_slot], operator: "AND" }
          ].map(&:with_indifferent_access)
        end

        it 'caches intermediate operations', :aggregate_failures do
          allow_next_instance_of(described_class) do |instance|
            allow(instance).to receive(:aggregated_metrics).and_return(aggregated_metrics)
          end

          params = { start_date: start_date, end_date: end_date, recorded_at: recorded_at }

          aggregated_metrics[0][:events].each do |event|
            expect(sources::RedisHll).to receive(:calculate_metrics_union)
                                           .with(params.merge(metric_names: event))
                                           .once
                                           .and_return(0)
          end

          2.upto(4) do |subset_size|
            aggregated_metrics[0][:events].combination(subset_size).each do |events|
              expect(sources::RedisHll).to receive(:calculate_metrics_union)
                                             .with(params.merge(metric_names: events))
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

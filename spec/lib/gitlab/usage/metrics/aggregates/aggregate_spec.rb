# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Aggregates::Aggregate, :clean_gitlab_redis_shared_state do
  let(:end_date) { Date.current }
  let(:namespace) { described_class.to_s.deconstantize.constantize }
  let(:sources) { Gitlab::Usage::Metrics::Aggregates::Sources }

  let_it_be(:recorded_at) { Time.current.to_i }

  describe '.calculate_count_for_aggregation' do
    using RSpec::Parameterized::TableSyntax

    before do
      %w[event1 event2].each do |event_name|
        allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_event?).with(event_name).and_return(true)
      end
    end

    context 'with valid configuration' do
      where(:number_of_days, :datasource, :attribute) do
        28 | 'redis_hll'       | 'user.id'
        7  | 'redis_hll'       | 'project.id'
        28 | 'database'        | 'user.id'
        7  | 'database'        | 'user.id'
        28 | 'internal_events' | 'user.id'
        7  | 'internal_events' | 'user.id'
      end

      with_them do
        let(:time_frame) { "#{number_of_days}d" }
        let(:start_date) { number_of_days.days.ago.to_date }
        let(:params) { { start_date: start_date, end_date: end_date, recorded_at: recorded_at } }
        let(:aggregate) do
          {
            source: datasource,
            events: %w[event1 event2],
            attribute: attribute
          }
        end

        subject(:calculate_count_for_aggregation) do
          described_class
            .new(recorded_at)
            .calculate_count_for_aggregation(aggregation: aggregate, time_frame: time_frame)
        end

        it 'returns the number of unique events for aggregation', :aggregate_failures do
          expect(namespace::SOURCES[datasource])
            .to receive(:calculate_metrics_union)
                  .with(params.merge(metric_names: %w[event1 event2], property_name: attribute))
                  .and_return(5)
          expect(calculate_count_for_aggregation).to eq(5)
        end
      end
    end

    # EE version has validation that doesn't allow undefined events
    # On CE, we detect EE events as undefined
    context 'when configuration includes undefined events', unless: Gitlab.ee? do
      let(:number_of_days) { 28 }

      before do
        allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_event?).with('event3').and_return(false)
      end

      where(:datasource, :expected_events) do
        'redis_hll' | %w[event1 event2]
        'database'  | %w[event1 event2 event3]
      end

      with_them do
        let(:time_frame) { "#{number_of_days}d" }
        let(:start_date) { number_of_days.days.ago.to_date }
        let(:params) { { start_date: start_date, end_date: end_date, recorded_at: recorded_at } }
        let(:aggregate) do
          {
            source: datasource,
            events: %w[event1 event2 event3]
          }
        end

        subject(:calculate_count_for_aggregation) do
          described_class
            .new(recorded_at)
            .calculate_count_for_aggregation(aggregation: aggregate, time_frame: time_frame)
        end

        it 'returns the number of unique events for aggregation', :aggregate_failures do
          expect(namespace::SOURCES[datasource])
            .to receive(:calculate_metrics_union)
                  .with(params.merge(metric_names: expected_events, property_name: nil))
                  .and_return(5)
          expect(calculate_count_for_aggregation).to eq(5)
        end
      end
    end

    context 'with invalid configuration' do
      where(:time_frame, :datasource, :expected_error) do
        '7d'  | 'mongodb'   | namespace::UnknownAggregationSource
        'all' | 'redis_hll' | namespace::DisallowedAggregationTimeFrame
      end

      with_them do
        let(:aggregate) do
          {
            source: datasource,
            events: %w[event1 event2]
          }
        end

        subject(:calculate_count_for_aggregation) do
          described_class
            .new(recorded_at)
            .calculate_count_for_aggregation(aggregation: aggregate, time_frame: time_frame)
        end

        context 'with non prod environment' do
          it 'raises error' do
            expect { calculate_count_for_aggregation }.to raise_error expected_error
          end
        end

        context 'with prod environment' do
          before do
            stub_rails_env('production')
          end

          it 'returns fallback value' do
            expect(calculate_count_for_aggregation).to be(-1)
          end
        end
      end
    end

    context 'when union data is not available' do
      subject(:calculate_count_for_aggregation) do
        described_class
          .new(recorded_at)
          .calculate_count_for_aggregation(aggregation: aggregate, time_frame: time_frame)
      end

      where(:time_frame, :datasource) do
        '28d' | 'redis_hll'
        '7d'  | 'database'
        '28d' | 'internal_events'
      end

      with_them do
        before do
          allow(namespace::SOURCES[datasource]).to receive(:calculate_metrics_union).and_raise(sources::UnionNotAvailable)
        end

        let(:aggregate) do
          {
            source: datasource,
            events: %w[event1 event2]
          }
        end

        context 'with non prod environment' do
          it 'raises error' do
            expect { calculate_count_for_aggregation }.to raise_error sources::UnionNotAvailable
          end
        end

        context 'with prod environment' do
          before do
            stub_rails_env('production')
          end

          it 'returns fallback value' do
            expect(calculate_count_for_aggregation).to be(-1)
          end
        end
      end
    end
  end
end

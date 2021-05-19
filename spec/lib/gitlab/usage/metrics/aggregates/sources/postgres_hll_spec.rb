# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll, :clean_gitlab_redis_shared_state do
  let_it_be(:start_date) { 7.days.ago }
  let_it_be(:end_date) { Date.current }
  let_it_be(:recorded_at) { Time.current }
  let_it_be(:time_period) { { created_at: (start_date..end_date) } }

  let(:metric_1) { 'metric_1' }
  let(:metric_2) { 'metric_2' }
  let(:metric_names) { [metric_1, metric_2] }

  describe 'metric calculations' do
    before do
      [
        {
          metric_name: metric_1,
          time_period: time_period,
          recorded_at_timestamp: recorded_at,
          data: ::Gitlab::Database::PostgresHll::Buckets.new(141 => 1, 56 => 1)
        },
        {
          metric_name: metric_2,
          time_period: time_period,
          recorded_at_timestamp: recorded_at,
          data: ::Gitlab::Database::PostgresHll::Buckets.new(10 => 1, 56 => 1)
        }
      ].each do |params|
        described_class.save_aggregated_metrics(**params)
      end
    end

    describe '.calculate_events_union' do
      subject(:calculate_metrics_union) do
        described_class.calculate_metrics_union(metric_names: metric_names, start_date: start_date, end_date: end_date, recorded_at: recorded_at)
      end

      it 'returns the number of unique events in the union of all metrics' do
        expect(calculate_metrics_union.round(2)).to eq(3.12)
      end

      context 'when there is no aggregated data saved' do
        let(:metric_names) { [metric_1, 'i do not have any records'] }

        it 'raises error when union data is missing' do
          expect { calculate_metrics_union }.to raise_error Gitlab::Usage::Metrics::Aggregates::Sources::UnionNotAvailable
        end
      end

      context 'when there is only one metric defined as aggregated' do
        let(:metric_names) { [metric_1] }

        it 'returns the number of unique events for that metric' do
          expect(calculate_metrics_union.round(2)).to eq(2.08)
        end
      end
    end

    describe '.calculate_metrics_intersections' do
      subject(:calculate_metrics_intersections) do
        described_class.calculate_metrics_intersections(metric_names: metric_names, start_date: start_date, end_date: end_date, recorded_at: recorded_at)
      end

      it 'returns the number of common events in the intersection of all metrics' do
        expect(calculate_metrics_intersections.round(2)).to eq(1.04)
      end

      context 'when there is no aggregated data saved' do
        let(:metric_names) { [metric_1, 'i do not have any records'] }

        it 'raises error when union data is missing' do
          expect { calculate_metrics_intersections }.to raise_error Gitlab::Usage::Metrics::Aggregates::Sources::UnionNotAvailable
        end
      end

      context 'when there is only one metric defined in aggregate' do
        let(:metric_names) { [metric_1] }

        it 'returns the number of common/unique events for the intersection of that metric' do
          expect(calculate_metrics_intersections.round(2)).to eq(2.08)
        end
      end
    end
  end

  describe '.save_aggregated_metrics' do
    subject(:save_aggregated_metrics) do
      described_class.save_aggregated_metrics(metric_name: metric_1,
                                              time_period: time_period,
                                              recorded_at_timestamp: recorded_at,
                                              data: data)
    end

    context 'with compatible data argument' do
      let(:data) { ::Gitlab::Database::PostgresHll::Buckets.new(141 => 1, 56 => 1) }

      it 'persists serialized data in Redis' do
        Gitlab::Redis::SharedState.with do |redis|
          expect(redis).to receive(:set).with("#{metric_1}_7d-#{recorded_at.to_i}", '{"141":1,"56":1}', ex: 120.hours)
        end

        save_aggregated_metrics
      end

      context 'with monthly key' do
        let_it_be(:start_date) { 4.weeks.ago }
        let_it_be(:time_period) { { created_at: (start_date..end_date) } }

        it 'persists serialized data in Redis' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis).to receive(:set).with("#{metric_1}_28d-#{recorded_at.to_i}", '{"141":1,"56":1}', ex: 120.hours)
          end

          save_aggregated_metrics
        end
      end

      context 'with all_time key' do
        let_it_be(:time_period) { nil }

        it 'persists serialized data in Redis' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis).to receive(:set).with("#{metric_1}_all-#{recorded_at.to_i}", '{"141":1,"56":1}', ex: 120.hours)
          end

          save_aggregated_metrics
        end
      end

      context 'error handling' do
        before do
          allow(Gitlab::Redis::SharedState).to receive(:with).and_raise(::Redis::CommandError)
        end

        it 'rescues and reraise ::Redis::CommandError for development and test environments' do
          expect { save_aggregated_metrics }.to raise_error ::Redis::CommandError
        end

        context 'for environment different than development' do
          before do
            stub_rails_env('production')
          end

          it 'rescues ::Redis::CommandError' do
            expect { save_aggregated_metrics }.not_to raise_error
          end
        end
      end
    end

    context 'with incompatible data argument' do
      let(:data) { 1 }

      context 'for environment different than development' do
        before do
          stub_rails_env('production')
        end

        it 'does not persist data in Redis' do
          Gitlab::Redis::SharedState.with do |redis|
            expect(redis).not_to receive(:set)
          end

          save_aggregated_metrics
        end
      end

      it 'raises error for development environment' do
        expect { save_aggregated_metrics }.to raise_error /Unsupported data type/
      end
    end
  end
end

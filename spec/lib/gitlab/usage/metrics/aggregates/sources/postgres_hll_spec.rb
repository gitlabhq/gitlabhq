# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll, :clean_gitlab_redis_shared_state do
  let_it_be(:start_date) { 7.days.ago }
  let_it_be(:end_date) { Date.current }
  let_it_be(:recorded_at) { Time.current }
  let_it_be(:time_period) { { created_at: (start_date..end_date) } }
  let_it_be(:property_name) { 'property1' }

  let(:metric_1) { 'metric_1' }
  let(:metric_2) { 'metric_2' }
  let(:metric_names) { [metric_1, metric_2] }
  let(:error_rate) { Gitlab::Database::PostgresHll::BatchDistinctCounter::ERROR_RATE }

  describe '.save_aggregated_metrics' do
    subject(:save_aggregated_metrics) do
      described_class.save_aggregated_metrics(
        metric_name: metric_1,
        time_period: time_period,
        recorded_at_timestamp: recorded_at,
        data: data
      )
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
        expect { save_aggregated_metrics }.to raise_error(/Unsupported data type/)
      end
    end
  end
end

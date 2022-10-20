# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::AggregatedMetric, :clean_gitlab_redis_shared_state do
  using RSpec::Parameterized::TableSyntax
  before do
    # weekly AND 1 weekly OR 2
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 1, time: 1.week.ago)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_unapprove, values: 1, time: 1.week.ago)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_unapprove, values: 2, time: 1.week.ago)

    # monthly AND 2 weekly OR 3
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 2, time: 2.weeks.ago)
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_unapprove, values: 3, time: 2.weeks.ago)

    # out of date range
    Gitlab::UsageDataCounters::HLLRedisCounter.track_event(:i_quickactions_approve, values: 3, time: 2.months.ago)

    # database events
    Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll
      .save_aggregated_metrics(
        metric_name: :i_quickactions_approve,
        time_period: { created_at: (1.week.ago..Date.current) },
        recorded_at_timestamp: Time.current,
        data: ::Gitlab::Database::PostgresHll::Buckets.new(141 => 1, 56 => 1)
      )
    Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll
      .save_aggregated_metrics(
        metric_name: :i_quickactions_unapprove,
        time_period: { created_at: (1.week.ago..Date.current) },
        recorded_at_timestamp: Time.current,
        data: ::Gitlab::Database::PostgresHll::Buckets.new(10 => 1, 56 => 1)
      )
  end

  where(:data_source, :time_frame, :operator, :expected_value) do
    'redis_hll' | '28d' | 'AND' | 2
    'redis_hll' | '28d' | 'OR'  | 3
    'redis_hll' | '7d'  | 'AND' | 1
    'redis_hll' | '7d'  | 'OR'  | 2
    'database'  | '7d'  | 'OR'  | 3.0
    'database'  | '7d'  | 'AND' | 1.0
  end

  with_them do
    let(:error_rate) { Gitlab::Database::PostgresHll::BatchDistinctCounter::ERROR_RATE }
    let(:metric_definition) do
      {
        data_source: data_source,
        time_frame: time_frame,
        options: {
          aggregate: {
            operator: operator
          },
          events: %w[
            i_quickactions_approve
            i_quickactions_unapprove
          ]
        }
      }
    end

    around do |example|
      freeze_time { example.run }
    end

    it 'has correct value' do
      expect(described_class.new(metric_definition).value).to be_within(error_rate).percent_of(expected_value)
    end
  end
end

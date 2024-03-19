# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::AggregatedMetric, :clean_gitlab_redis_shared_state,
  feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  before do
    redis_counter_class = Gitlab::UsageDataCounters::HLLRedisCounter

    # weekly AND 1 weekly OR 2
    redis_counter_class.track_event(:g_edit_by_snippet_ide, values: 1, time: 1.week.ago, property_name: :user)
    redis_counter_class.track_event(:g_edit_by_web_ide, values: 1, time: 1.week.ago, property_name: :user)
    redis_counter_class.track_event(:g_edit_by_web_ide, values: 2, time: 1.week.ago, property_name: :user)

    # monthly AND 2 weekly OR 3
    redis_counter_class.track_event(:g_edit_by_snippet_ide, values: 2, time: 2.weeks.ago, property_name: :user)
    redis_counter_class.track_event(:g_edit_by_web_ide, values: 3, time: 2.weeks.ago, property_name: :user)

    # different property_name
    redis_counter_class.track_event(:g_edit_by_web_ide, values: 4, time: 1.week.ago, property_name: :project)

    # out of date range
    redis_counter_class.track_event(:g_edit_by_snippet_ide, values: 3, time: 2.months.ago, property_name: :user)

    # database events
    Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll
      .save_aggregated_metrics(
        metric_name: :g_edit_by_snippet_ide,
        time_period: { created_at: (1.week.ago..Date.current) },
        recorded_at_timestamp: Time.current,
        data: ::Gitlab::Database::PostgresHll::Buckets.new(141 => 1, 56 => 1)
      )
    Gitlab::Usage::Metrics::Aggregates::Sources::PostgresHll
      .save_aggregated_metrics(
        metric_name: :g_edit_by_web_ide,
        time_period: { created_at: (1.week.ago..Date.current) },
        recorded_at_timestamp: Time.current,
        data: ::Gitlab::Database::PostgresHll::Buckets.new(10 => 1, 56 => 1)
      )
  end

  where(:data_source, :time_frame, :attribute, :expected_value) do
    'redis_hll' | '28d' | 'user.id'    | 3
    'redis_hll' | '7d'  | 'user.id'    | 2
    'redis_hll' | '7d'  | 'project.id' | 1
    'database'  | '7d'  | 'user.id'    | 3.0
  end

  with_them do
    let(:error_rate) { Gitlab::Database::PostgresHll::BatchDistinctCounter::ERROR_RATE }
    let(:metric_definition) do
      {
        data_source: data_source,
        time_frame: time_frame,
        options: {
          aggregate: {
            attribute: attribute
          },
          events: %w[
            g_edit_by_snippet_ide
            g_edit_by_web_ide
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

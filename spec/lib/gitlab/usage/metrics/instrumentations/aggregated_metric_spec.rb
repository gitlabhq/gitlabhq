# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::Metrics::Instrumentations::AggregatedMetric, :clean_gitlab_redis_shared_state,
  feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  before do
    stub_feature_flags(redis_hll_property_name_tracking: property_name_flag_enabled)

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

  where(:data_source, :time_frame, :attribute, :expected_value, :property_name_flag_enabled) do
    'redis_hll' | '28d' | 'user_id'    | 3   | true
    'redis_hll' | '28d' | 'user_id'    | 4   | false
    'redis_hll' | '28d' | 'project_id' | 4   | false
    'redis_hll' | '7d'  | 'user_id'    | 2   | true
    'redis_hll' | '7d'  | 'project_id' | 1   | true
    'database'  | '7d'  | 'user_id'    | 3.0 | true
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

  context "with not allowed aggregate attribute" do
    let(:property_name_flag_enabled) { true }
    let(:metric_definition) do
      {
        data_source: 'redis_hll',
        time_frame: '28d',
        options: {
          aggregate: {
            attribute: 'project.name'
          },
          events: %w[
            g_edit_by_snippet_ide
            g_edit_by_web_ide
          ]
        }
      }
    end

    it "raises an error" do
      error_class = Gitlab::Usage::MetricDefinition::InvalidError
      expect { described_class.new(metric_definition).value }.to raise_error(error_class)
    end
  end
end

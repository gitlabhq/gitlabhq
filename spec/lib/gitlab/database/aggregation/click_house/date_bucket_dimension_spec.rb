# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::DateBucketDimension, :click_house, feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'
      self.table_primary_key = %w[namespace_path user_id session_id flow_type]

      dimensions do
        date_bucket :started_event_at, :date, -> { sql('anyIfMerge(started_event_at)') }, parameters: {
          granularity: { type: :string, in: %w[weekly monthly] }
        }
      end

      metrics do
        count
      end
    end
  end

  let(:session1) do # march bucket
    created_at = DateTime.parse('2025-03-01 00:00:00 UTC')
    { session_id: 1, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 10.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:session2) do # march bucket
    created_at = DateTime.parse('2025-03-12 00:00:00 UTC')
    { session_id: 2, user_id: 2, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 3.minutes,
      resumed_event_at: created_at + 2.minutes }
  end

  let(:session3) do # april bucket
    created_at = DateTime.parse('2025-04-04 00:00:00 UTC')
    { session_id: 3, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'code_review', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      dropped_event_at: created_at + 10.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:all_data_rows) do
    [session1, session2, session3]
  end

  it 'returns monthly buckets by default' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :started_event_at }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { started_event_at: Date.parse('2025-03-01'), total_count: 2 },
      { started_event_at: Date.parse('2025-04-01'), total_count: 1 }
    ])
  end

  it 'returns specified buckets if provided' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :started_event_at, parameters: { granularity: 'weekly' } }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { started_event_at_weekly: Date.parse('2025-03-01').beginning_of_week, total_count: 1 },
      { started_event_at_weekly: Date.parse('2025-03-12').beginning_of_week, total_count: 1 },
      { started_event_at_weekly: Date.parse('2025-04-01').beginning_of_week, total_count: 1 }
    ])
  end

  it 'returns errors if granularity is not allowed' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :started_event_at, parameters: { granularity: 'daily' } }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).with_errors(array_including(
      a_string_matching(%r{Unknown granularity "daily"})
    ))
  end
end

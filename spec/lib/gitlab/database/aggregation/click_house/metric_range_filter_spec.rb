# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::MetricRangeFilter, :click_house,
  feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'

      dimensions do
        column :user_id, :integer
      end

      metrics do
        count
        count :sessions, :integer
      end

      filters do
        metric_range :total_count, :integer
      end
    end
  end

  let(:session_user1_a) do
    created_at = DateTime.parse('2025-03-01 00:00:00 UTC')
    { session_id: 1, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat',
      environment: 'prod', session_year: 2025, created_event_at: created_at }
  end

  let(:session_user1_b) do
    created_at = DateTime.parse('2025-03-02 00:00:00 UTC')
    { session_id: 2, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat',
      environment: 'prod', session_year: 2025, created_event_at: created_at }
  end

  let(:session_user1_c) do
    created_at = DateTime.parse('2025-03-03 00:00:00 UTC')
    { session_id: 3, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat',
      environment: 'prod', session_year: 2025, created_event_at: created_at }
  end

  let(:session_user2) do
    created_at = DateTime.parse('2025-03-04 00:00:00 UTC')
    { session_id: 4, user_id: 2, project_id: 1, namespace_path: '1/2/', flow_type: 'chat',
      environment: 'prod', session_year: 2025, created_event_at: created_at }
  end

  let(:all_data_rows) { [session_user1_a, session_user1_b, session_user1_c, session_user2] }

  it 'applies a closed range as HAVING BETWEEN' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :total_count, values: 2..3 }],
      dimensions: [{ identifier: :user_id }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { user_id: 1, total_count: 3 }
    ])
  end

  it 'applies an open-ended range as HAVING >=' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :total_count, values: 2..nil }],
      dimensions: [{ identifier: :user_id }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { user_id: 1, total_count: 3 }
    ])
  end

  it 'applies a beginless range as HAVING <=' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :total_count, values: nil..1 }],
      dimensions: [{ identifier: :user_id }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { user_id: 2, total_count: 1 }
    ])
  end

  it 'is invalid when the underlying metric is not requested' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :total_count, values: 1..2 }],
      dimensions: [{ identifier: :user_id }],
      metrics: [{ identifier: :sessions_count }]
    )

    expect(engine).to execute_aggregation(request).with_errors([
      a_string_matching(/metric `total_count` must be requested to filter by it/)
    ])
  end
end

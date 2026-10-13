# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::ExactMatchFilter, :click_house,
  feature_category: :value_stream_management do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'

      metrics do
        count
      end

      filters do
        exact_match :session_id, :integer
        exact_match :created_event_at, :integer, -> { sql('anyIfMerge(created_event_at)') }, merge_column: true
      end
    end
  end

  it 'applies single value filter' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :session_id, values: [1] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 1 }
    ])
  end

  it 'applies single value filter for merge columns' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :created_event_at, values: ['2025-03-01 00:00:00'] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 1 }
    ])
  end

  it 'applies multiple values filter' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :session_id, values: [1, 2] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 2 }
    ])
  end
end

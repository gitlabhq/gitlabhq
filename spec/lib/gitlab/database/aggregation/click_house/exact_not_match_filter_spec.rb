# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::ExactNotMatchFilter, :click_house,
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
        exact_not_match :session_id, :integer
        exact_not_match :flow_type, :string, nil, max_size: 1, formatter: ->(values) { values.map(&:downcase) }
        exact_not_match :created_event_at, :integer, -> { sql('anyIfMerge(created_event_at)') }, merge_column: true
        exact_not_match :finished_event_at, :integer, -> { sql('anyIfMerge(finished_event_at)') }, merge_column: true
      end
    end
  end

  describe '#identifier' do
    it 'suffixes the column name with `_not`' do
      expect(described_class.new(:status, :string).identifier).to eq(:status_not)
    end

    it 'does not clash with the exact_match filter on the same column' do
      expect(engine_definition.filters.map(&:identifier))
        .to include(:session_id, :session_id_not)
    end
  end

  it 'excludes a single value' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :session_id_not, values: [1] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 2 }
    ])
  end

  it 'excludes multiple values' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :session_id_not, values: [1, 2] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 1 }
    ])
  end

  it 'excludes values for merge columns' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :created_event_at_not, values: ['2025-03-01 00:00:00'] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 2 }
    ])
  end

  # session3 has no finished_event_at.
  it 'excludes rows where the column is NULL' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :finished_event_at_not, values: ['2025-03-01 00:10:00'] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 1 }
    ])
  end

  it 'combines with the exact_match filter on the same column' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [
        { identifier: :session_id, values: [1, 2] },
        { identifier: :session_id_not, values: [2] }
      ],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 1 }
    ])
  end

  it 'applies the formatter to the values before excluding them' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :flow_type_not, values: ['CHAT'] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 1 }
    ])
  end

  it 'enforces max_size' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :flow_type_not, values: %w[chat code_review] }],
      metrics: [{ identifier: :total_count }]
    )
    query_plan = request.to_query_plan(engine)

    expect(query_plan).not_to be_valid
    expect(query_plan.errors.to_a).to include('Values maximum size of 1 exceeded for filter `flow_type_not`')
  end
end

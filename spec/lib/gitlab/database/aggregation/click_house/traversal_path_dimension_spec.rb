# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::TraversalPathDimension, :click_house,
  feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  # The fixture stores organization-scoped paths in `namespace_path`: `7/1/2/` is
  # organization 7, top-level group 1, subgroup 2.
  def session(id, namespace_path)
    created_at = DateTime.parse('2025-03-01 00:00:00 UTC') + id.days

    { session_id: id, user_id: id, project_id: 1, namespace_path: namespace_path, flow_type: 'chat',
      environment: 'prod', session_year: 2025, created_event_at: created_at, started_event_at: created_at + 1.second }
  end

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'

      dimensions do
        traversal_path :group_id, :integer, -> { sql('namespace_path') }, association: true
        traversal_path :shallow_group_id, :integer, -> { sql('namespace_path') }, parameters: {
          depth: { in: 1..2 }
        }
      end

      metrics do
        count
      end
    end
  end

  let(:all_data_rows) do
    [
      session(1, '7/1/'),
      session(2, '7/1/2/'),
      session(3, '7/1/2/3/'),
      session(4, '7/4/5/'),
      session(5, '0/'),
      session(6, '7/abc/')
    ]
  end

  def request_for(identifier, parameters = nil)
    Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: identifier, parameters: parameters }.compact],
      metrics: [{ identifier: :total_count }]
    )
  end

  it 'groups by the top-level group, skipping the organization segment, by default' do
    expect(engine).to execute_aggregation(request_for(:group_id)).and_return(match_array([
      { group_id: 1, total_count: 3 },
      { group_id: 4, total_count: 1 },
      { group_id: nil, total_count: 2 }
    ]))
  end

  it 'groups by the segment at the requested depth' do
    expect(engine).to execute_aggregation(request_for(:group_id, { depth: 2 })).and_return(match_array([
      { group_id_2: 2, total_count: 2 },
      { group_id_2: 5, total_count: 1 },
      { group_id_2: nil, total_count: 3 }
    ]))
  end

  it 'resolves the association alias with the depth parameter and keeps the dimension row key' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :group, parameters: { depth: 2 } }],
      metrics: [{ identifier: :total_count }],
      order: [{ identifier: :group, parameters: { depth: 2 }, direction: :desc }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { group_id_2: 5, total_count: 1 },
      { group_id_2: 2, total_count: 2 },
      { group_id_2: nil, total_count: 3 }
    ])
  end

  it 'returns NULL for paths shorter than the requested depth' do
    expect(engine).to execute_aggregation(request_for(:group_id, { depth: 4 })).and_return([
      { group_id_4: nil, total_count: 6 }
    ])
  end

  it 'declares a bounded depth parameter by default' do
    expect(engine_definition.dimensions.first.parameters).to match(
      depth: hash_including(type: :integer, in: 1..described_class::MAX_DEPTH,
        description: a_string_matching(/top-level group/))
    )
  end

  it 'accepts the maximum depth' do
    depth = described_class::MAX_DEPTH

    expect(engine).to execute_aggregation(request_for(:group_id, { depth: depth })).and_return([
      { "group_id_#{depth}": nil, total_count: 6 }
    ])
  end

  context 'when depth is outside the allowed range' do
    using RSpec::Parameterized::TableSyntax

    where(:depth) do
      [0, -1, described_class::MAX_DEPTH + 1]
    end

    with_them do
      it 'returns a validation error' do
        expect(engine).to execute_aggregation(request_for(:group_id, { depth: depth })).with_errors(
          array_including(a_string_matching(/Invalid value\(s\) for parameter `depth`: #{depth}/))
        )
      end
    end
  end

  it 'merges engine-provided depth parameter options' do
    expect(engine_definition.dimensions.last.parameters).to match(depth: hash_including(type: :integer, in: 1..2))

    expect(engine).to execute_aggregation(request_for(:shallow_group_id, { depth: 3 })).with_errors(
      array_including(a_string_matching(/Invalid value\(s\) for parameter `depth`: 3/))
    )
  end
end

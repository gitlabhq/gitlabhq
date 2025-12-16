# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ActiveRecord::Engine, feature_category: :database do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request1) do
    create(:merge_request, :unique_branches,
      updated_by_id: user.id,
      target_project: project,
      source_project: project,
      time_estimate: 1,
      created_at: '2025-04-05').tap do |mr|
      mr.metrics.update!(merged_at: '2025-05-03')
    end
  end

  let_it_be(:merge_request2) do
    create(:merge_request, :unique_branches,
      target_project: project,
      source_project: project,
      time_estimate: 3,
      created_at: '2025-04-04').tap do |mr|
        mr.metrics.update!(latest_closed_at: '2025-05-03')
      end
  end

  let_it_be(:merge_request3) do
    create(:merge_request, updated_by_id: user.id, time_estimate: 5, created_at: '2025-06-05').tap do |mr|
      mr.metrics.update!(merged_at: '2025-06-04')
    end
  end

  let(:engine_definition) do
    described_class.build do
      dimensions do
        column :state_id, :integer, description: 'Integer representation of the existing merge request states'
        column :updated_by_id, :integer, description: 'User id value who last updated the the merge request'
        column :project_id, :integer, description: 'ID of the associated project'
        timestamp_column :created_at, :timestamp, description: 'Bucketed creation timestamp (month)',
          parameters: { granularity: { type: :string, in: %w[monthly daily] } }
        timestamp_column :merged_at,
          :timestamp,
          -> { MergeRequest::Metrics.arel_table[:merged_at] },
          parameters: { granularity: { type: :string, in: %w[monthly weekly] } },
          scope_proc: ->(scope, _ctx) { scope.joins(:metrics).where.not(merge_request_metrics: { merged_at: nil }) },
          description: 'Bucketed merge timestamp (month or week).'
        timestamp_column :closed_at,
          :timestamp,
          -> { MergeRequest::Metrics.arel_table[:latest_closed_at] },
          parameters: { granularity: { type: :string, in: %w[monthly weekly] } },
          scope_proc: ->(scope, _ctx) { scope.joins(:metrics) },
          description: 'Bucketed merge timestamp (month or week).'
        column :state,
          :string,
          -> { MergeRequest.arel_table[:state_id] },
          formatter: ->(v) { MergeRequest.available_states.invert[v] },
          description: 'String representation of the existing merge request states.'
      end

      metrics do
        count description: 'Total record count'
        mean :time_estimate, :float, description: 'Mean time estimate'
        mean :time_estimate_with_block, :float, -> { MergeRequest.arel_table[:time_estimate] }
      end
    end
  end

  let(:engine) { engine_definition.new(context: { scope: MergeRequest.all }) }

  it 'mean time_estimate by state_id' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :state_id }],
      metrics: [{ identifier: :mean_time_estimate }, { identifier: :mean_time_estimate_with_block }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      state_id: 1, mean_time_estimate: 3.0, mean_time_estimate_with_block: 3.0
    ])
  end

  it 'count by project_id sorted' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :project_id }],
      metrics: [{ identifier: :total_count }],
      order: [{ identifier: :total_count, direction: :desc }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { project_id: project.id, total_count: 2 },
      { project_id: merge_request3.project_id, total_count: 1 }
    ])
  end

  it 'count by month' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :created_at, parameters: { granularity: 'monthly' } }],
      metrics: [{ identifier: :total_count }],
      order: [{ identifier: :created_at, parameters: { granularity: 'monthly' }, direction: :desc }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { created_at_monthly: merge_request3.created_at.beginning_of_month, total_count: 1 },
      { created_at_monthly: merge_request1.created_at.beginning_of_month, total_count: 2 }
    ])
  end

  it 'group and order by the same timestamp column with different granularity' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [
        { identifier: :created_at, parameters: { granularity: 'monthly' } },
        { identifier: :created_at, parameters: { granularity: 'daily' } }
      ],
      metrics: [{ identifier: :total_count }],
      order: [
        { identifier: :created_at, parameters: { granularity: 'monthly' }, direction: :desc },
        { identifier: :created_at, parameters: { granularity: 'daily' }, direction: :asc }
      ]
    )

    expect(engine).to execute_aggregation(request).and_return([
      {
        created_at_monthly: merge_request3.created_at.beginning_of_month,
        created_at_daily: merge_request3.created_at.beginning_of_day,
        total_count: 1
      },
      {
        created_at_monthly: merge_request2.created_at.beginning_of_month,
        created_at_daily: merge_request2.created_at.beginning_of_day,
        total_count: 1
      },
      {
        created_at_monthly: merge_request1.created_at.beginning_of_month,
        created_at_daily: merge_request1.created_at.beginning_of_day,
        total_count: 1
      }
    ])
  end

  it 'count by state' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :state }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { state: 'opened', total_count: 3 }
    ])
  end

  it 'global count' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 3 }
    ])
  end

  it 'count by monthly merged_at' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :merged_at, parameters: { granularity: 'monthly' } }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { merged_at_monthly: merge_request1.metrics.merged_at.beginning_of_month, total_count: 1 },
      { merged_at_monthly: merge_request3.metrics.merged_at.beginning_of_month, total_count: 1 }
    ])
  end

  describe 'null value handling' do
    context 'when column with integer type returns null values' do
      it 'groups null values together' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :updated_by_id }],
          metrics: [{ identifier: :total_count }]
        )

        expect(engine).to execute_aggregation(request).and_return([
          { updated_by_id: user.id, total_count: 2 },
          { updated_by_id: nil, total_count: 1 }
        ])
      end
    end

    context 'when timestamp_column dimension returns null values' do
      it 'groups null values together' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :closed_at, parameters: { granularity: 'monthly' } }],
          metrics: [{ identifier: :total_count }]
        )

        expect(engine).to execute_aggregation(request).and_return([
          { closed_at_monthly: merge_request2.metrics.latest_closed_at.beginning_of_month, total_count: 1 },
          { closed_at_monthly: nil, total_count: 2 }
        ])
      end
    end
  end

  describe '.to_hash' do
    it 'exposes the engine_definition definition' do
      expect(engine_definition.to_hash).to match({
        dimensions: array_including(
          hash_including({ identifier: :state_id, name: :state_id })
        ),
        metrics: array_including(
          hash_including({ identifier: :total_count })
        )
      })
    end
  end

  describe 'validations' do
    context 'when metric cannot be found' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :state_id }],
          metrics: [{ identifier: :missing_identfier }]
        )

        expect(engine).to execute_aggregation(request).with_errors(array_including(
          a_string_matching(/identifier is not available: 'missing_identfier'/)
        ))
      end
    end

    context 'when dimension cannot be found' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :missing_identfier }],
          metrics: [{ identifier: :mean_time_estimate }]
        )

        expect(engine).to execute_aggregation(request).with_errors(array_including(
          a_string_matching(/identifier is not available: 'missing_identfier'/)
        ))
      end
    end

    context 'when no metric is passed in' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :state_id }],
          metrics: []
        )

        expect(engine).to execute_aggregation(request).with_errors(array_including(
          a_string_matching(/at least one metric is required/)
        ))
      end
    end

    context 'when dimensions limit is reached' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [
            { identifier: :state_id },
            { identifier: :project_id },
            { identifier: :state },
            { identifier: :merged_at, parameters: { granularity: 'monthly' } }
          ],
          metrics: [{ identifier: :mean_time_estimate }]
        )

        expect(engine).to execute_aggregation(request).with_errors(array_including(
          a_string_matching(/maximum two dimensions/)
        ))
      end
    end

    context 'when order cannot be found' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :state_id }],
          metrics: [{ identifier: :mean_time_estimate }],
          order: [{ identifier: :unknown, direction: :asc }]
        )

        expect(engine).to execute_aggregation(request).with_errors(array_including(
          a_string_matching(/identifier is not available/)
        ))
      end
    end

    context 'when duplicated dimensions are passed in' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :state_id }, { identifier: :state_id }],
          metrics: [{ identifier: :mean_time_estimate }]
        )

        expect(engine).to execute_aggregation(request).with_errors(array_including(
          a_string_matching(/duplicated identifier found: state_id/)
        ))
      end
    end

    context 'when duplicated metrics are passed in' do
      it 'returns error' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :state_id }],
          metrics: [{ identifier: :mean_time_estimate }, { identifier: :mean_time_estimate }]
        )

        expect(engine).to execute_aggregation(request).with_errors(array_including(
          a_string_matching(/duplicated identifier found: mean_time_estimate/)
        ))
      end
    end
  end
end

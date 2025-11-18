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
      created_at: '2025-04-05').tap do |mr|
        mr.metrics.update!(latest_closed_at: '2025-05-03')
      end
  end

  let_it_be(:merge_request3) do
    create(:merge_request, updated_by_id: user.id, time_estimate: 5, created_at: '2025-06-05').tap do |mr|
      mr.metrics.update!(merged_at: '2025-06-04')
    end
  end

  let(:engine) do
    described_class.build do
      dimensions do
        column :state_id, :integer, description: 'Integer representation of the existing merge request states'
        column :updated_by_id, :integer, description: 'User id value who last updated the the merge request'
        column :project_id, :integer, description: 'ID of the associated project'
        timestamp_column :created_at, :timestamp, granularities: [:month],
          description: 'Bucketed creation timestamp (month)'
        timestamp_column :merged_at,
          :timestamp,
          granularities: [:month, :week],
          expression: -> { MergeRequest::Metrics.arel_table[:merged_at] },
          scope_proc: ->(scope, _ctx) { scope.joins(:metrics).where.not(merge_request_metrics: { merged_at: nil }) },
          description: 'Bucketed merge timestamp (month or week).'
        timestamp_column :closed_at,
          :timestamp,
          granularities: [:month, :week],
          expression: -> { MergeRequest::Metrics.arel_table[:latest_closed_at] },
          scope_proc: ->(scope, _ctx) { scope.joins(:metrics) },
          description: 'Bucketed merge timestamp (month or week).'
        column :state,
          :string,
          expression: -> { MergeRequest.arel_table[:state_id] },
          formatter: ->(v) { MergeRequest.available_states.invert[v] },
          description: 'String representation of the existing merge request states.'
      end

      metrics do
        count description: 'Total record count'
        mean :time_estimate, :float, description: 'Mean time estimate'
      end
    end
  end

  let(:ctx) do
    {
      scope: MergeRequest.where({}),
      arel_table: MergeRequest.arel_table
    }
  end

  it 'mean time_estimate by state_id' do
    plan = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :column_state_id }],
      metrics: [{ identifier: :mean_time_estimate }]
    )

    result = engine.new(context: ctx).execute(plan)

    expect(result).to be_success
    expect(result.payload[:data]).to eq([{
      dimensions: [{ integer_value: 1 }],
      metrics: [{ float_value: 3 }]
    }])
  end

  it 'count by project_id sorted' do
    plan = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :column_project_id }],
      metrics: [{ identifier: :count }],
      order: [{ type: :metric, identifier: :count, direction: :desc }]
    )

    result = engine.new(context: ctx).execute(plan)
    expect(result.payload[:data]).to eq([
      {
        dimensions: [{ integer_value: project.id }],
        metrics: [{ integer_value: 2 }]
      },
      {
        dimensions: [{ integer_value: merge_request3.project_id }],
        metrics: [{ integer_value: 1 }]
      }
    ])
  end

  it 'count by month' do
    plan = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :timestamp_column_created_at, granularity: :month }],
      metrics: [{ identifier: :count }],
      order: [{ type: :dimension, identifier: :timestamp_column_created_at, direction: :desc }]
    )

    result = engine.new(context: ctx).execute(plan)
    expect(result.payload[:data]).to eq([
      {
        dimensions: [{ timestamp_value: merge_request3.created_at.beginning_of_month }],
        metrics: [{ integer_value: 1 }]
      },
      {
        dimensions: [{ timestamp_value: merge_request1.created_at.beginning_of_month }],
        metrics: [{ integer_value: 2 }]
      }
    ])
  end

  it 'count by state' do
    plan = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :column_state }],
      metrics: [{ identifier: :count }]
    )

    result = engine.new(context: ctx).execute(plan)
    expect(result.payload[:data]).to eq([{
      dimensions: [{ string_value: 'opened' }],
      metrics: [{ integer_value: 3 }]
    }])
  end

  it 'global count' do
    plan = Gitlab::Database::Aggregation::Request.new(
      dimensions: [],
      metrics: [{ identifier: :count }]
    )

    result = engine.new(context: ctx).execute(plan)
    expect(result.payload[:data]).to eq([{
      dimensions: [],
      metrics: [{ integer_value: 3 }]
    }])
  end

  it 'count by monthly merged_at' do
    plan = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :timestamp_column_merged_at, granularity: :month }],
      metrics: [{ identifier: :count }]
    )

    result = engine.new(context: ctx).execute(plan)
    expect(result.payload[:data]).to eq([
      {
        dimensions: [{ timestamp_value: merge_request1.metrics.merged_at.beginning_of_month }],
        metrics: [{ integer_value: 1 }]
      },
      {
        dimensions: [{ timestamp_value: merge_request3.metrics.merged_at.beginning_of_month }],
        metrics: [{ integer_value: 1 }]
      }
    ])
  end

  describe 'null value handling' do
    context 'when column with integer type returns null values' do
      it 'groups null values together' do
        plan = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :column_updated_by_id }],
          metrics: [{ identifier: :count }]
        )

        result = engine.new(context: ctx).execute(plan)
        expect(result.payload[:data]).to eq([
          {
            dimensions: [{ integer_value: user.id }],
            metrics: [{ integer_value: 2 }]
          },
          {
            dimensions: [{ integer_value: nil }],
            metrics: [{ integer_value: 1 }]
          }
        ])
      end
    end

    context 'when timestamp_column dimension returns null values' do
      it 'groups null values together' do
        plan = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :timestamp_column_closed_at, granularity: :month }],
          metrics: [{ identifier: :count }]
        )

        result = engine.new(context: ctx).execute(plan)
        expect(result.payload[:data]).to eq([
          {
            dimensions: [{ timestamp_value: merge_request2.metrics.latest_closed_at.beginning_of_month }],
            metrics: [{ integer_value: 1 }]
          },
          {
            dimensions: [{ timestamp_value: nil }],
            metrics: [{ integer_value: 2 }]
          }
        ])
      end
    end
  end

  describe '.to_hash' do
    it 'exposes the engine definition' do
      expect(engine.to_hash).to match({
        dimensions: array_including(
          hash_including({ identifier: :column_state_id, name: :state_id })
        ),
        metrics: array_including(
          hash_including({ identifier: :count })
        )
      })
    end
  end

  describe 'validations' do
    context 'when metric cannot be found' do
      it 'returns error' do
        plan = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :column_state_id }],
          metrics: [{ identifier: :missing_identfier }]
        )

        result = engine.new(context: ctx).execute(plan)
        expect(result.payload[:errors][:metrics]).to include(
          a_string_matching(/identifier is not available: 'missing_identfier'/)
        )
      end
    end

    context 'when dimension cannot be found' do
      it 'returns error' do
        plan = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :missing_identfier }],
          metrics: [{ identifier: :mean_time_estimate }]
        )

        result = engine.new(context: ctx).execute(plan)
        expect(result.payload[:errors][:dimensions]).to include(
          a_string_matching(/identifier is not available: 'missing_identfier'/)
        )
      end
    end

    context 'when no metric is passed in' do
      it 'returns error' do
        plan = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :column_state_id }],
          metrics: []
        )

        result = engine.new(context: ctx).execute(plan)
        expect(result.payload[:errors][:metrics]).to include(a_string_matching(/at least one metric is required/))
      end
    end

    context 'when dimensions limit is reached' do
      it 'returns error' do
        plan = Gitlab::Database::Aggregation::Request.new(
          dimensions: [
            { identifier: :column_state_id },
            { identifier: :column_project_id },
            { identifier: :column_state },
            { identifier: :timestamp_column_merged_at, default_granularity: :month }
          ],
          metrics: [{ identifier: :mean_time_estimate }]
        )

        result = engine.new(context: ctx).execute(plan)
        expect(result.payload[:errors][:dimensions]).to include(a_string_matching(/maximum two dimensions/))
      end
    end

    context 'when order cannot be found' do
      it 'returns error' do
        plan = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :column_state_id }],
          metrics: [{ identifier: :mean_time_estimate }],
          order: [{ identifier: :unknown, direction: :asc }]
        )

        result = engine.new(context: ctx).execute(plan)
        expect(result.payload[:errors][:order]).to include(a_string_matching(/identifier is not available/))
      end
    end
  end
end

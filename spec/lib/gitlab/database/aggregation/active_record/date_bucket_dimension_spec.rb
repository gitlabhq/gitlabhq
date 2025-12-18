# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ActiveRecord::DateBucketDimension, feature_category: :database do
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
    Gitlab::Database::Aggregation::ActiveRecord::Engine.build do
      dimensions do
        date_bucket :created_at, :datetime, description: 'Bucketed creation timestamp (month)',
          parameters: { granularity: { type: :string, in: %w[monthly daily] } }
        date_bucket :merged_at,
          :datetime,
          -> { MergeRequest::Metrics.arel_table[:merged_at] },
          parameters: { granularity: { type: :string, in: %w[monthly weekly] } },
          scope_proc: ->(scope, _ctx) { scope.joins(:metrics).where.not(merge_request_metrics: { merged_at: nil }) },
          description: 'Bucketed merge timestamp (month or week).'
      end

      metrics do
        count
      end
    end
  end

  let(:engine) { engine_definition.new(context: { scope: MergeRequest.all }) }

  it 'groups by simple bucket' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :created_at, parameters: { granularity: 'monthly' } }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { created_at_monthly: merge_request1.created_at.beginning_of_month, total_count: 2 },
      { created_at_monthly: merge_request3.created_at.beginning_of_month, total_count: 1 }
    ])
  end

  it 'uses monthly as default granularity' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :created_at, parameters: {} }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { created_at: merge_request1.created_at.beginning_of_month, total_count: 2 },
      { created_at: merge_request3.created_at.beginning_of_month, total_count: 1 }
    ])
  end

  it 'groups by custom expression and scope' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :merged_at, parameters: { granularity: 'monthly' } }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { merged_at_monthly: merge_request1.metrics.merged_at.beginning_of_month, total_count: 1 },
      { merged_at_monthly: merge_request3.metrics.merged_at.beginning_of_month, total_count: 1 }
    ])
  end

  it 'returns errors if granularity is not allowed' do
    request = Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :merged_at, parameters: { granularity: 'daily' } }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).with_errors(array_including(
      a_string_matching(%r{Unknown granularity "daily"})
    ))
  end
end

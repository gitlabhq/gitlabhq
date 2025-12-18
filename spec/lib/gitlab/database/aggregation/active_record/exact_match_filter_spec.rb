# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ActiveRecord::ExactMatchFilter, feature_category: :database do
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
      filters do
        exact_match :created_at, :datetime, max_size: 2
        exact_match :created_at_with_expr, :datetime, -> { sql('created_at') }
      end

      metrics do
        count
      end
    end
  end

  let(:engine) { engine_definition.new(context: { scope: MergeRequest.all }) }

  it 'applies single value filter' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :created_at, values: ['2025-04-04'] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 1 }
    ])
  end

  it 'applies single value filter defined by expression' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :created_at_with_expr, values: ['2025-04-04'] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 1 }
    ])
  end

  it 'applies multiple values filter' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :created_at, values: %w[2025-04-04 2025-04-05] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 2 }
    ])
  end

  it 'respects max_size limit' do
    request = Gitlab::Database::Aggregation::Request.new(
      filters: [{ identifier: :created_at, values: %w[2025-04-04 2025-04-05 2025-05-05] }],
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).with_errors([
      "Values maximum size of 2 exceeded for filter `created_at`"
    ])
  end
end

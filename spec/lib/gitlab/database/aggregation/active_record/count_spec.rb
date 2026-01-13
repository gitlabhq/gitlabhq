# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ActiveRecord::Count, feature_category: :database do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:merge_request1) do
    create(:merge_request, :unique_branches,
      target_project: project,
      source_project: project,
      created_at: '2025-04-05')
  end

  let_it_be(:merge_request2) do
    create(:merge_request, :unique_branches,
      target_project: project,
      source_project: project,
      created_at: '2025-04-04')
  end

  let_it_be(:merge_request3) do
    create(:merge_request, created_at: '2025-06-05')
  end

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ActiveRecord::Engine.build do
      metrics do
        count
        count :custom
      end
    end
  end

  let(:engine) { engine_definition.new(context: { scope: MergeRequest.all }) }

  it 'calcualtes simple count' do
    request = Gitlab::Database::Aggregation::Request.new(
      metrics: [{ identifier: :total_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { total_count: 3 }
    ])
  end

  it 'calculates count with custom name' do
    request = Gitlab::Database::Aggregation::Request.new(
      metrics: [{ identifier: :custom_count }]
    )

    expect(engine).to execute_aggregation(request).and_return([
      { custom_count: 3 }
    ])
  end
end

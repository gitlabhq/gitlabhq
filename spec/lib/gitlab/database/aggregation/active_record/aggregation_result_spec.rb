# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ActiveRecord::AggregationResult, feature_category: :database do
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
      end
    end
  end

  describe '#load_data' do
    it 'executes provided query without loading model' do
      engine = engine_definition.new(context: {})
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :total_count }]
      )
      query_plan = Gitlab::Database::Aggregation::QueryPlan.new(engine, request)
      results = described_class.new(engine, query_plan, MergeRequest.select('id')).to_a
      expect(results).to match_array([
        { 'id' => merge_request1.id },
        { 'id' => merge_request2.id },
        { 'id' => merge_request3.id }
      ])
    end
  end
end

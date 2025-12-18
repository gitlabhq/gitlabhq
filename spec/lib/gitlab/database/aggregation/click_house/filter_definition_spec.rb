# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::FilterDefinition, feature_category: :database do
  it 'requires #apply definition' do
    expect(described_class.new(:foo, :bar)).to require_method_definition(:apply, nil, nil)
  end

  describe 'validations' do
    let(:engine_definition) do
      Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_name = 'agent_platform_sessions'
        self.table_primary_key = %w[namespace_path user_id session_id flow_type]

        metrics do
          count
        end

        filters do
          exact_match :session_id, :integer, nil, max_size: 1
        end
      end
    end

    let(:engine) { engine_definition.new(context: {}) }

    describe 'max_size' do
      it 'is valid when values.count <= max_size' do
        request = Gitlab::Database::Aggregation::Request.new(
          filters: [{ identifier: :session_id, values: [1] }],
          metrics: [{ identifier: :total_count }]
        )
        query_plan = request.to_query_plan(engine)
        expect(query_plan).to be_valid
      end

      it 'is valid when values.count <= max_size' do
        request = Gitlab::Database::Aggregation::Request.new(
          filters: [{ identifier: :session_id, values: [1, 2] }],
          metrics: [{ identifier: :total_count }]
        )
        query_plan = request.to_query_plan(engine)
        expect(query_plan).not_to be_valid
        expect(query_plan.errors.to_a).to include('Values maximum size of 1 exceeded for filter `session_id`')
      end
    end
  end
end

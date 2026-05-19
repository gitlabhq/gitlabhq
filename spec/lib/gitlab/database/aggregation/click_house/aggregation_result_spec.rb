# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::AggregationResult, :click_house, feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'

      dimensions do
        column :flow_type, :string
      end

      metrics do
        count
      end
    end
  end

  let(:all_data_rows) do
    [
      { user_id: 1, namespace_path: '1/', project_id: 1, session_id: 1, flow_type: 'chat', environment: 'prod',
        session_year: 2025 },
      { user_id: 2, namespace_path: '1/', project_id: 1, session_id: 2, flow_type: 'chat', environment: 'prod',
        session_year: 2025 },
      { user_id: 3, namespace_path: '1/', project_id: 1, session_id: 3, flow_type: 'duo', environment: 'prod',
        session_year: 2025 }
    ]
  end

  let(:request) do
    Gitlab::Database::Aggregation::Request.new(
      dimensions: [{ identifier: :flow_type }],
      metrics: [{ identifier: :total_count }]
    )
  end

  let(:aggregation_result) { engine.execute(request).payload[:data] }

  describe '#count' do
    it 'returns the number of aggregated rows via a database query' do
      expect(aggregation_result.count).to eq(2)
    end

    it 'does not load rows into memory' do
      expect(aggregation_result).not_to receive(:load_data)
      aggregation_result.count
    end
  end
end

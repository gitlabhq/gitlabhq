# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::Rate, :click_house, feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'
      self.table_primary_key = %w[namespace_path user_id session_id flow_type]

      metrics do
        rate :completion, numerator_if: -> { Arel.sql('anyIfMerge(finished_event_at) IS NOT NULL') }
        rate :finished_to_dropped,
          denominator_if: -> { Arel.sql('anyIfMerge(dropped_event_at) IS NOT NULL') },
          numerator_if: -> { Arel.sql('anyIfMerge(finished_event_at) IS NOT NULL') }
      end
    end
  end

  let(:session1) do # finished & long
    created_at = DateTime.parse('2025-03-01 00:00:00 UTC')
    { session_id: 1, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 10.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:session2) do # finished & short
    created_at = DateTime.parse('2025-03-02 00:00:00 UTC')
    { session_id: 2, user_id: 2, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 3.minutes,
      resumed_event_at: created_at + 2.minutes }
  end

  let(:session3) do # dropped
    created_at = DateTime.parse('2025-03-04 00:00:00 UTC')
    { session_id: 3, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'code_review', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      dropped_event_at: created_at + 10.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:all_data_rows) do
    [session1, session2, session3]
  end

  describe "rate with numerator only" do
    it 'returns numerator/total_count rate' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :completion_rate }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { completion_rate: 2.0 / 3 }
      ])
    end
  end

  describe "rate with numerator and denominator" do
    it 'returns numerator/denominator rate' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :finished_to_dropped_rate }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { finished_to_dropped_rate: 2.0 }
      ])
    end
  end
end

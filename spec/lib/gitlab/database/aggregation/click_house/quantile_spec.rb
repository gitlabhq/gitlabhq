# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::Quantile, :click_house, feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'
      self.table_primary_key = %w[namespace_path user_id session_id flow_type]

      metrics do
        quantile :duration, :float,
          -> { Arel.sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))") }
        quantile :duration_with_param, :float,
          -> { Arel.sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))") },
          parameters: { quantile: { type: :float } }
      end
    end
  end

  let(:session1) do # finished 1.minute
    created_at = DateTime.parse('2025-03-01 00:00:00 UTC')
    { session_id: 1, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 1.minute,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:session2) do # finished 2 minutes
    created_at = DateTime.parse('2025-03-02 00:00:00 UTC')
    { session_id: 2, user_id: 2, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 2.minutes,
      resumed_event_at: created_at + 2.minutes }
  end

  let(:session3) do # finished 3 minutes
    created_at = DateTime.parse('2025-03-02 00:00:00 UTC')
    { session_id: 3, user_id: 2, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 3.minutes,
      resumed_event_at: created_at + 2.minutes }
  end

  let(:session4) do # finished 4 minutes
    created_at = DateTime.parse('2025-03-02 00:00:00 UTC')
    { session_id: 4, user_id: 2, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 4.minutes,
      resumed_event_at: created_at + 2.minutes }
  end

  let(:session5) do # finished 5 minutes
    created_at = DateTime.parse('2025-03-02 00:00:00 UTC')
    { session_id: 5, user_id: 2, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 5.minutes,
      resumed_event_at: created_at + 2.minutes }
  end

  let(:session6) do # dropped
    created_at = DateTime.parse('2025-03-04 00:00:00 UTC')
    { session_id: 6, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'code_review', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      dropped_event_at: created_at + 10.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:session7) do # in progress
    created_at = DateTime.parse('2025-03-04 00:00:00 UTC')
    { session_id: 7, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'code_review', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:all_data_rows) do
    [session1, session2, session3, session4, session5, session6, session7]
  end

  describe "quantile without param" do
    it 'returns median' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :duration_quantile }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { duration_quantile: 180.0 }
      ])
    end

    it 'ignores passed param' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :duration_quantile, parameters: { quantile: 0.1 } }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { duration_quantile: 180.0 }
      ])
    end
  end

  describe "quantile with param" do
    it 'returns median by default' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :duration_with_param_quantile }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { duration_with_param_quantile: 180.0 }
      ])
    end

    it 'uses passed param' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :duration_with_param_quantile, parameters: { quantile: 0.1 } }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { duration_with_param_quantile_14be4: 84.0 }
      ])
    end
  end
end

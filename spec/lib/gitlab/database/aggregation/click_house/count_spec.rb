# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::Count, :click_house, feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'
      self.table_primary_key = %w[namespace_path user_id session_id flow_type]

      metrics do
        count
        count :finished, if: -> { Arel.sql('anyIfMerge(finished_event_at) IS NOT NULL') }
        count :users, :integer, -> { Arel.sql('user_id') }, distinct: true
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

  let(:session3) do # not finished yet. in progress
    created_at = DateTime.parse('2025-03-04 00:00:00 UTC')
    { session_id: 3, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'code_review', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:all_data_rows) do
    [session1, session2, session3]
  end

  describe "count" do
    it 'returns total sessions count' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :total_count }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { total_count: all_data_rows.count }
      ])
    end
  end

  describe "count distinct" do
    it 'returns number of distinct users' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :users_count }]
      )

      user_ids = all_data_rows.pluck(:user_id)
      expect(user_ids.count).not_to eq(user_ids.uniq.count)

      expect(engine).to execute_aggregation(request).and_return([
        { users_count: user_ids.uniq.count }
      ])
    end
  end

  describe "conditional count" do
    it 'returns sessions count with condition fulfilled' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :finished_count }]
      )

      finished_timestamps = all_data_rows.pluck(:finished_event_at)
      expect(finished_timestamps.count).not_to eq(finished_timestamps.compact.count)

      expect(engine).to execute_aggregation(request).and_return([
        { finished_count: finished_timestamps.compact.count }
      ])
    end
  end
end

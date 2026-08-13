# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::Max, :click_house, feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'

      metrics do
        max :session_id, :integer
        max :session_id_finished, :integer, ->(_params) {
          Arel.sql('session_id')
        }, if: ->(_params) { Arel.sql('anyIfMerge(finished_event_at) IS NOT NULL') }
      end
    end
  end

  let(:session1) do
    created_at = DateTime.parse('2025-03-01 00:00:00 UTC')
    { session_id: 1, user_id: 1, project_id: 1,
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 10.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:session2) do
    created_at = DateTime.parse('2025-03-02 00:00:00 UTC')
    { session_id: 2, user_id: 2, project_id: 1,
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 3.minutes,
      resumed_event_at: created_at + 2.minutes }
  end

  let(:session3) do
    created_at = DateTime.parse('2025-03-04 00:00:00 UTC')
    { session_id: 3, user_id: 1, project_id: 1,
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:all_data_rows) do
    [session1, session2, session3]
  end

  describe "max" do
    it 'returns maximum of session_id values' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :max_session_id }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { max_session_id: 3 }
      ])
    end
  end

  describe "max with condition" do
    it 'returns maximum of session_id values for finished sessions only' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :max_session_id_finished }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { max_session_id_finished: 2 }
      ])
    end
  end
end

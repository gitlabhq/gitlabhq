# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::RetainedCount, :click_house, feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'
  include_context 'with 3-day agent_platform_sessions window data'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'

      filters do
        exact_match :flow_type, :string
      end

      dimensions do
        date_bucket :event_date, :date, -> { Arel.sql('anyIfMerge(created_event_at)') }, parameters: {
          granularity: { type: :string, in: %w[daily] }
        }
      end

      metrics do
        count
        retained_count :returning_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
        retained_count :two_periods_retained, :integer, -> { Arel.sql('user_id') }, over: :event_date, lag_offset: 2
      end
    end
  end

  let(:daily_event_date) { { identifier: :event_date, parameters: { granularity: 'daily' } } }

  describe 'retained_count with default lag_offset' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :returning_users_count }]
      )
    end

    it 'returns the count of users present in both the current and previous day' do
      # Day 1: (1,2), no prior -> 0
      # Day 2: (1,3) intersect (1,2) -> 1 (user 1)
      # Day 3: (2)   intersect (1,3) -> 0
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-01'), returning_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), returning_users_count: 1 },
        { event_date_daily: Date.parse('2025-03-03'), returning_users_count: 0 }
      ])
    end
  end

  describe 'retained_count with custom lag_offset' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :two_periods_retained_count }]
      )
    end

    it 'returns the count of users present in both the current day and two days prior' do
      # Day 3: (2) intersect Day 1 (1,2) -> 1 (user 2)
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-01'), two_periods_retained_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), two_periods_retained_count: 0 },
        { event_date_daily: Date.parse('2025-03-03'), two_periods_retained_count: 1 }
      ])
    end
  end

  describe 'retained_count combined with a regular metric' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :total_count }, { identifier: :returning_users_count }]
      )
    end

    it 'returns both the retained user count and total session count per day' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-01'), total_count: 2, returning_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), total_count: 2, returning_users_count: 1 },
        { event_date_daily: Date.parse('2025-03-03'), total_count: 1, returning_users_count: 0 }
      ])
    end
  end

  describe 'retained_count with filtering' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :flow_type, values: ['chat'] }],
        dimensions: [daily_event_date],
        metrics: [{ identifier: :returning_users_count }]
      )
    end

    it 'computes retained count only over the filtered subset' do
      # chat-only: Day 1 (1,2); Day 2 (1); Day 3 (2).
      # Retained vs prev: 0; (1) intersect (1,2) = 1; (2) intersect (1) = 0.
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-01'), returning_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), returning_users_count: 1 },
        { event_date_daily: Date.parse('2025-03-03'), returning_users_count: 0 }
      ])
    end
  end

  describe 'retained_count with ordering' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :returning_users_count }],
        order: [{ identifier: :event_date, parameters: { granularity: 'daily' }, direction: :desc }]
      )
    end

    it 'returns results ordered by the specified dimension' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-03'), returning_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), returning_users_count: 1 },
        { event_date_daily: Date.parse('2025-03-01'), returning_users_count: 0 }
      ])
    end
  end

  describe 'multiple lag offsets in one query' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :returning_users_count }, { identifier: :two_periods_retained_count }]
      )
    end

    it 'returns both lag_offset=1 and lag_offset=2 results together' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-01'), returning_users_count: 0, two_periods_retained_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), returning_users_count: 1, two_periods_retained_count: 0 },
        { event_date_daily: Date.parse('2025-03-03'), returning_users_count: 0, two_periods_retained_count: 1 }
      ])
    end
  end

  describe 'retained_count without its over dimension requested' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :returning_users_count }]
      )
    end

    it 'surfaces a validation error from the engine' do
      expect(engine).to execute_aggregation(request).with_errors(array_including(
        a_string_matching(/metric 'returning_users_count' requires dimension 'event_date' to be requested/)
      ))
    end
  end
end

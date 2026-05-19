# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::LaggedCount, :click_house, feature_category: :database do
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
        lagged_count :previous_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
        lagged_count :two_periods_ago_users, :integer, -> { Arel.sql('user_id') }, over: :event_date, lag_offset: 2
      end
    end
  end

  let(:daily_event_date) { { identifier: :event_date, parameters: { granularity: 'daily' } } }

  describe 'lagged_count with default lag_offset' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :previous_users_count }]
      )
    end

    it 'returns the distinct user count from the previous period' do
      # Day 1: no prior window -> 0
      # Day 2: previous day had users (1, 2) -> 2
      # Day 3: previous day had users (1, 3) -> 2
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-01'), previous_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), previous_users_count: 2 },
        { event_date_daily: Date.parse('2025-03-03'), previous_users_count: 2 }
      ])
    end
  end

  describe 'lagged_count with custom lag_offset' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :two_periods_ago_users_count }]
      )
    end

    it 'returns the distinct user count from two periods ago' do
      # Day 3 (2 periods ago = Day 1): users (1, 2) -> 2
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-01'), two_periods_ago_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), two_periods_ago_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-03'), two_periods_ago_users_count: 2 }
      ])
    end
  end

  describe 'lagged_count combined with a regular metric' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :total_count }, { identifier: :previous_users_count }]
      )
    end

    it 'returns both the lagged user count and total session count per day' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-01'), total_count: 2, previous_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), total_count: 2, previous_users_count: 2 },
        { event_date_daily: Date.parse('2025-03-03'), total_count: 1, previous_users_count: 2 }
      ])
    end
  end

  describe 'lagged_count with filtering' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :flow_type, values: ['chat'] }],
        dimensions: [daily_event_date],
        metrics: [{ identifier: :previous_users_count }]
      )
    end

    it 'computes lagged count only over the filtered subset' do
      # chat-only: Day 1 (1,2); Day 2 (1); Day 3 (2). Lagged by 1: 0, 2, 1.
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-01'), previous_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), previous_users_count: 2 },
        { event_date_daily: Date.parse('2025-03-03'), previous_users_count: 1 }
      ])
    end
  end

  describe 'lagged_count with ordering' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :previous_users_count }],
        order: [{ identifier: :event_date, parameters: { granularity: 'daily' }, direction: :desc }]
      )
    end

    it 'returns results ordered by the specified dimension' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-03'), previous_users_count: 2 },
        { event_date_daily: Date.parse('2025-03-02'), previous_users_count: 2 },
        { event_date_daily: Date.parse('2025-03-01'), previous_users_count: 0 }
      ])
    end
  end

  describe 'multiple lag offsets in one query' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :previous_users_count }, { identifier: :two_periods_ago_users_count }]
      )
    end

    it 'returns both lag_offset=1 and lag_offset=2 results together' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_daily: Date.parse('2025-03-01'), previous_users_count: 0, two_periods_ago_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-02'), previous_users_count: 2, two_periods_ago_users_count: 0 },
        { event_date_daily: Date.parse('2025-03-03'), previous_users_count: 2, two_periods_ago_users_count: 2 }
      ])
    end
  end

  describe 'lagged_count without its over dimension requested' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :previous_users_count }]
      )
    end

    it 'surfaces a validation error from the engine' do
      expect(engine).to execute_aggregation(request).with_errors(array_including(
        a_string_matching(/metric 'previous_users_count' requires dimension 'event_date' to be requested/)
      ))
    end
  end
end

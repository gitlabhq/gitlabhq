# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::AcquiredCount, :click_house, feature_category: :database do
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
        acquired_count :new_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
        acquired_count :two_periods_new, :integer, -> { Arel.sql('user_id') }, over: :event_date, lag_offset: 2
        acquired_count :new_environments, :integer, -> { Arel.sql('environment') }, over: :event_date
      end
    end
  end

  let(:daily_event_date) { { identifier: :event_date, parameters: { granularity: 'daily' } } }

  describe 'acquired_count with default lag_offset' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :new_users_count }]
      )
    end

    it 'returns the count of users present in the current but not the previous day' do
      # Day 1: (1,2), no prior -> both are new -> 2
      # Day 2: (1,3) minus (1,2) -> 1 (user 3)
      # Day 3: (2)   minus (1,3) -> 1 (user 2)
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), new_users_count: 2 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), new_users_count: 1 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), new_users_count: 1 }
      ])
    end
  end

  describe 'acquired_count with custom lag_offset' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :two_periods_new_count }]
      )
    end

    it 'returns the count of users present on the current day but not two days prior' do
      # Days 1 and 2 have no bucket two positions back, so every user counts as acquired.
      # Day 3: (2) minus Day 1 (1,2) -> 0
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), two_periods_new_count: 2 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), two_periods_new_count: 2 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), two_periods_new_count: 0 }
      ])
    end
  end

  describe 'acquired_count combined with a regular metric' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :total_count }, { identifier: :new_users_count }]
      )
    end

    it 'returns both the acquired user count and total session count per day' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), total_count: 2, new_users_count: 2 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), total_count: 2, new_users_count: 1 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), total_count: 1, new_users_count: 1 }
      ])
    end
  end

  describe 'acquired_count with filtering' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :flow_type, values: ['chat'] }],
        dimensions: [daily_event_date],
        metrics: [{ identifier: :new_users_count }]
      )
    end

    it 'computes acquired count only over the filtered subset' do
      # chat-only: Day 1 (1,2); Day 2 (1); Day 3 (2).
      # Acquired vs prev: 2; (1) minus (1,2) = 0; (2) minus (1) = 1.
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), new_users_count: 2 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), new_users_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), new_users_count: 1 }
      ])
    end
  end

  describe 'acquired_count with ordering' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :new_users_count }],
        order: [{ identifier: :event_date, parameters: { granularity: 'daily' }, direction: :desc }]
      )
    end

    it 'returns results ordered by the specified dimension' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-03'), new_users_count: 1 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), new_users_count: 1 },
        { event_date_granularity_daily: Date.parse('2025-03-01'), new_users_count: 2 }
      ])
    end
  end

  describe 'multiple lag offsets in one query' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :new_users_count }, { identifier: :two_periods_new_count }]
      )
    end

    it 'returns both lag_offset=1 and lag_offset=2 results together' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), new_users_count: 2, two_periods_new_count: 2 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), new_users_count: 1, two_periods_new_count: 2 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), new_users_count: 1, two_periods_new_count: 0 }
      ])
    end
  end

  describe 'acquired_count without its over dimension requested' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :new_users_count }]
      )
    end

    it 'surfaces a validation error from the engine' do
      expect(engine).to execute_aggregation(request).with_errors(array_including(
        a_string_matching(/metric 'new_users_count' requires dimension 'event_date' to be requested/)
      ))
    end
  end

  describe 'acquired_count over a column outside the table primary key' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :new_environments_count }]
      )
    end

    # environment is not part of the agent_platform_sessions sort key, so it only resolves
    # because to_inner_arel projects the expression instead of relying on the primary key
    # passthrough. Every row is 'prod', so only the first day acquires it.
    it 'projects the expression column explicitly' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), new_environments_count: 1 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), new_environments_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), new_environments_count: 0 }
      ])
    end
  end
end

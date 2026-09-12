# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::ChurnedCount, :click_house, feature_category: :database do
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
        churned_count :churned_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
        churned_count :two_periods_churned, :integer, -> { Arel.sql('user_id') }, over: :event_date, lag_offset: 2
        churned_count :churned_environments, :integer, -> { Arel.sql('environment') }, over: :event_date
      end
    end
  end

  let(:daily_event_date) { { identifier: :event_date, parameters: { granularity: 'daily' } } }

  describe 'churned_count with default lag_offset' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :churned_users_count }]
      )
    end

    it 'returns the count of users present on the previous but not the current day' do
      # Day 1: no prior day -> 0
      # Day 2: (1,2) minus (1,3) -> 1 (user 2)
      # Day 3: (1,3) minus (2)   -> 2 (users 1 and 3)
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), churned_users_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), churned_users_count: 1 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), churned_users_count: 2 }
      ])
    end
  end

  describe 'churned_count with custom lag_offset' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :two_periods_churned_count }]
      )
    end

    it 'returns the count of users present two days prior but not on the current day' do
      # Days 1 and 2 have no bucket two positions back, so nothing can have churned.
      # Day 3: Day 1 (1,2) minus (2) -> 1 (user 1)
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), two_periods_churned_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), two_periods_churned_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), two_periods_churned_count: 1 }
      ])
    end
  end

  describe 'churned_count combined with a regular metric' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :total_count }, { identifier: :churned_users_count }]
      )
    end

    it 'returns both the churned user count and total session count per day' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), total_count: 2, churned_users_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), total_count: 2, churned_users_count: 1 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), total_count: 1, churned_users_count: 2 }
      ])
    end
  end

  describe 'churned_count with filtering' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :flow_type, values: ['chat'] }],
        dimensions: [daily_event_date],
        metrics: [{ identifier: :churned_users_count }]
      )
    end

    it 'computes churned count only over the filtered subset' do
      # chat-only: Day 1 (1,2); Day 2 (1); Day 3 (2).
      # Churned vs prev: 0; (1,2) minus (1) = 1 (user 2); (1) minus (2) = 1 (user 1).
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), churned_users_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), churned_users_count: 1 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), churned_users_count: 1 }
      ])
    end
  end

  describe 'churned_count with ordering' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :churned_users_count }],
        order: [{ identifier: :event_date, parameters: { granularity: 'daily' }, direction: :desc }]
      )
    end

    it 'returns results ordered by the specified dimension' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-03'), churned_users_count: 2 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), churned_users_count: 1 },
        { event_date_granularity_daily: Date.parse('2025-03-01'), churned_users_count: 0 }
      ])
    end
  end

  describe 'multiple lag offsets in one query' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :churned_users_count }, { identifier: :two_periods_churned_count }]
      )
    end

    it 'returns both lag_offset=1 and lag_offset=2 results together' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), churned_users_count: 0,
          two_periods_churned_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), churned_users_count: 1,
          two_periods_churned_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), churned_users_count: 2,
          two_periods_churned_count: 1 }
      ])
    end
  end

  describe 'churned_count without its over dimension requested' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :churned_users_count }]
      )
    end

    it 'surfaces a validation error from the engine' do
      expect(engine).to execute_aggregation(request).with_errors(array_including(
        a_string_matching(/metric 'churned_users_count' requires dimension 'event_date' to be requested/)
      ))
    end
  end

  describe 'churned_count over a column outside the table primary key' do
    let(:request) do
      Gitlab::Database::Aggregation::Request.new(
        dimensions: [daily_event_date],
        metrics: [{ identifier: :churned_environments_count }]
      )
    end

    # environment is not part of the agent_platform_sessions sort key, so it only resolves
    # because to_inner_arel projects the expression instead of relying on the primary key
    # passthrough. Every row is 'prod', so it never churns.
    it 'projects the expression column explicitly' do
      expect(engine).to execute_aggregation(request).and_return([
        { event_date_granularity_daily: Date.parse('2025-03-01'), churned_environments_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-02'), churned_environments_count: 0 },
        { event_date_granularity_daily: Date.parse('2025-03-03'), churned_environments_count: 0 }
      ])
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::Rate, :click_house,
  feature_category: :value_stream_management do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    Gitlab::Database::Aggregation::ClickHouse::Engine.build do
      self.table_name = 'agent_platform_sessions'

      dimensions do
        column :flow_type, :string
      end

      filters do
        exact_match :environment, :string
        metric_range :completion_rate, :float
        metric_range :finished_to_dropped_rate, :float
      end

      metrics do
        rate :completion, numerator_if: ->(_params) { Arel.sql('anyIfMerge(finished_event_at) IS NOT NULL') }
        rate :finished_to_dropped,
          denominator_if: ->(_params) { Arel.sql('anyIfMerge(dropped_event_at) IS NOT NULL') },
          numerator_if: ->(_params) { Arel.sql('anyIfMerge(finished_event_at) IS NOT NULL') }
        rate :unmatched_denominator,
          denominator_if: ->(_params) { Arel.sql('FALSE') },
          numerator_if: ->(_params) { Arel.sql('anyIfMerge(finished_event_at) IS NOT NULL') }
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

  describe "parameterized rate" do
    let(:engine_definition) do
      Gitlab::Database::Aggregation::ClickHouse::Engine.build do
        self.table_name = 'agent_platform_sessions'

        metrics do
          rate :by_flow,
            numerator_if: ->(params) { Arel.sql("flow_type = '#{params[:flow_type]}'") },
            parameters: {
              flow_type: { type: :string }
            }
        end
      end
    end

    it 'passes parameter values as hash to numerator_if' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :by_flow_rate, parameters: { flow_type: 'chat' } }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { by_flow_rate_chat: 2.0 / 3 }
      ])
    end

    it 'generates a unique result key per parameter combination' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [
          { identifier: :by_flow_rate, parameters: { flow_type: 'chat' } },
          { identifier: :by_flow_rate, parameters: { flow_type: 'code_review' } }
        ]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { by_flow_rate_chat: 2.0 / 3, by_flow_rate_code_review: 1.0 / 3 }
      ])
    end
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

  describe "rate using the count(*) denominator over an empty result set" do
    it 'returns NULL rather than nan' do
      # No dimensions are requested, so GROUP BY ALL still yields one aggregate
      # row even though the filter matches nothing, making count(*) zero.
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :environment, values: ['no_such_environment'] }],
        metrics: [{ identifier: :completion_rate }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { completion_rate: nil }
      ])
    end
  end

  describe "rate with a denominator matching no rows" do
    it 'returns NULL rather than inf or nan' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :unmatched_denominator_rate }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { unmatched_denominator_rate: nil }
      ])
    end
  end

  describe "rate combined with a dimension" do
    it 'computes a rate per dimension value, with NULL where the denominator is zero' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :flow_type }],
        metrics: [{ identifier: :completion_rate }, { identifier: :unmatched_denominator_rate }],
        order: [{ identifier: :flow_type, direction: :asc }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { flow_type: 'chat', completion_rate: 1.0, unmatched_denominator_rate: nil },
        { flow_type: 'code_review', completion_rate: 0.0, unmatched_denominator_rate: nil }
      ])
    end
  end

  describe "ordering by a rate" do
    it 'sorts by the rate value' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :flow_type }],
        metrics: [{ identifier: :completion_rate }],
        order: [{ identifier: :completion_rate, direction: :desc }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { flow_type: 'chat', completion_rate: 1.0 },
        { flow_type: 'code_review', completion_rate: 0.0 }
      ])
    end
  end

  describe "filtering on a rate with metric_range" do
    it 'excludes groups with a zero denominator from a lower-bound filter' do
      # The JSON response format renders both NULL and inf as null, so only a filter,
      # which is applied in SQL, can tell the guarded result from an unguarded one.
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :flow_type }],
        metrics: [{ identifier: :finished_to_dropped_rate }],
        filters: [{ identifier: :finished_to_dropped_rate, values: 0.5.. }]
      )

      expect(engine).to execute_aggregation(request).and_return([])
    end

    it 'keeps only the groups whose rate falls inside the range' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :flow_type }],
        metrics: [{ identifier: :completion_rate }],
        filters: [{ identifier: :completion_rate, values: 0.5..1.0 }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { flow_type: 'chat', completion_rate: 1.0 }
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

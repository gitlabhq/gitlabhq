# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::Engine, :click_house, feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    described_class.build do
      self.table_name = 'agent_platform_sessions'
      self.table_primary_key = %w[namespace_path user_id session_id flow_type]

      dimensions do
        column :user_id, :integer
        column :flow_type, :string
        column :duration, :integer, -> {
          Arel.sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))")
        }
        column :environment, :string, nil, formatter: ->(v) { v.upcase }
      end

      metrics do
        count
        mean :duration, :float, -> {
          Arel.sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))")
        }
        quantile :duration, :float,
          -> { Arel.sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))") },
          parameters: { quantile: { type: :float } }
        count :with_format, :integer, nil, formatter: ->(v) { v * -1 }
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

  let(:session3) do # in progress
    created_at = DateTime.parse('2025-03-04 00:00:00 UTC')
    { session_id: 3, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:session4) do # dropped
    created_at = DateTime.parse('2025-03-04 00:00:00 UTC')
    { session_id: 4, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      dropped_event_at: created_at + 10.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:session5) do # finished medium
    created_at = DateTime.parse('2025-04-04 00:00:00 UTC')
    { session_id: 5, user_id: 1, project_id: 1, namespace_path: '1/2/', flow_type: 'chat', environment: 'prod',
      session_year: 2025,
      created_event_at: created_at,
      started_event_at: created_at + 1.second,
      finished_event_at: created_at + 7.minutes,
      resumed_event_at: created_at + 9.minutes }
  end

  let(:all_data_rows) do
    [session1, session2, session3, session4, session5]
  end

  describe "dimensions" do
    it 'groups by single dimension' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :total_count }]
      )

      expect(engine).to execute_aggregation(request).and_return(match_array([
        { user_id: 2, total_count: 1 },
        { user_id: 1, total_count: 4 }
      ]))
    end

    it 'groups by multiple dimensions' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }, { identifier: :flow_type }],
        metrics: [{ identifier: :total_count }]
      )

      expect(engine).to execute_aggregation(request).and_return(match_array([
        { user_id: 2, flow_type: 'chat', total_count: 1 },
        { user_id: 1, flow_type: 'chat', total_count: 4 }
      ]))
    end

    it 'groups by column with expression' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :duration }],
        metrics: [{ identifier: :total_count }]
      )

      expect(engine).to execute_aggregation(request).and_return(match_array([
        { duration: nil, total_count: 2 },
        { duration: 600, total_count: 1 },
        { duration: 180, total_count: 1 },
        { duration: 420, total_count: 1 }
      ]))
    end
  end

  describe "sorting" do
    it 'accepts metric sort' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :duration }],
        metrics: [{ identifier: :total_count }],
        order: [{ identifier: :total_count, direction: :asc }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { duration: 420, total_count: 1 },
        { duration: 180, total_count: 1 },
        { duration: 600, total_count: 1 },
        { duration: nil, total_count: 2 }
      ])
    end

    it 'accepts dimension sort' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :duration }],
        metrics: [{ identifier: :total_count }],
        order: [{ identifier: :duration, direction: :asc }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { duration: 180, total_count: 1 },
        { duration: 420, total_count: 1 },
        { duration: 600, total_count: 1 },
        { duration: nil, total_count: 2 }
      ])
    end

    it 'accepts multiple orders' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :duration }],
        metrics: [{ identifier: :total_count }],
        order: [
          { identifier: :total_count, direction: :desc },
          { identifier: :duration, direction: :asc }
        ]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { duration: nil, total_count: 2 },
        { duration: 180, total_count: 1 },
        { duration: 420, total_count: 1 },
        { duration: 600, total_count: 1 }
      ])
    end

    it 'accepts order by parameterized metric' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :duration_quantile, parameters: { quantile: 0.1 } }],
        order: [
          { identifier: :duration_quantile, parameters: { quantile: 0.1 }, direction: :desc }
        ]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { user_id: 1, duration_quantile_14be4: 438 },
        { user_id: 2, duration_quantile_14be4: 180 }
      ])
    end
  end

  describe "formatting" do
    it 'applies formatting if defined' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :environment }],
        metrics: [{ identifier: :with_format_count }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { environment: "PROD", with_format_count: -5 }
      ])
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Aggregation::ClickHouse::Engine, :click_house, feature_category: :database do
  include_context 'with agent_platform_sessions ClickHouse aggregation engine'

  let(:engine_definition) do
    described_class.build do
      self.table_name = 'agent_platform_sessions'

      filters do
        exact_match :user_id, :integer
        range :created_event_at, :datetime, -> { Arel.sql('anyIfMerge(created_event_at)') }, merge_column: true
        metric_range :total_count, :integer
        metric_range :duration_quantile, :float
      end

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

  describe "filtering" do
    it 'applies merge column filtering' do
      filter_range = session1[:created_event_at].to_date..session4[:created_event_at].to_date

      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :created_event_at, values: filter_range }],
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :total_count }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { user_id: 2, total_count: 1 },
        { user_id: 1, total_count: 3 }
      ])
    end

    it 'applies regular filtering' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :user_id, values: [1] }],
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :total_count }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { user_id: 1, total_count: 4 }
      ])
    end

    it 'filters on aggregated metric via HAVING' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :total_count, values: 2..nil }],
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :total_count }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { user_id: 1, total_count: 4 }
      ])
    end

    it 'filters on a parameterized metric, targeting the requested instance' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :duration_quantile, parameters: { quantile: 0.1 }, values: 200..nil }],
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :duration_quantile, parameters: { quantile: 0.1 } }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { user_id: 1, duration_quantile_14be4: 438 }
      ])
    end

    it 'is invalid when filter parameters do not match any requested metric instance' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :duration_quantile, parameters: { quantile: 0.1 }, values: 200..nil }],
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :duration_quantile, parameters: { quantile: 0.5 } }]
      )

      expect(engine).to execute_aggregation(request).with_errors([
        a_string_matching(/metric `duration_quantile` must be requested to filter by it/)
      ])
    end
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

  describe '.table_name=' do
    it 'raises ArgumentError when the table is not in the ClickHouse schema cache' do
      expect do
        described_class.build do
          self.table_name = 'some_unknown_table'
        end
      end.to raise_error(ArgumentError, /not found in the ClickHouse schema cache/)
    end

    it 'auto-configures versioning for ReplacingMergeTree tables with version and deleted_marker' do
      klass = described_class.build { self.table_name = 'ci_finished_builds' }

      expect(klass.versioning_config).to eq(column: 'version', deleted_marker: 'deleted')
    end

    it 'does not configure versioning for non-ReplacingMergeTree tables' do
      klass = described_class.build { self.table_name = 'agent_platform_sessions' }

      expect(klass.versioning_config).to be_nil
    end

    it 'allows an explicit versioned_by call to override auto-detection' do
      klass = described_class.build do
        self.table_name = 'ci_finished_builds'
        versioned_by :version
      end

      expect(klass.versioning_config).to eq(column: 'version', deleted_marker: nil)
    end
  end

  describe '.table_primary_key' do
    it 'returns the primary key column names from the ClickHouse schema cache' do
      klass = described_class.build { self.table_name = 'agent_platform_sessions' }

      expect(klass.table_primary_key).to eq(%w[namespace_path user_id session_id flow_type])
    end

    it 'returns nil when `table_name` is not set' do
      klass = described_class.build {} # rubocop:disable Lint/EmptyBlock -- block is required

      expect(klass.table_primary_key).to be_nil
    end

    it 'allows an explicit table_primary_key= call to override auto-detection' do
      klass = described_class.build do
        self.table_name = 'agent_platform_sessions'
        self.table_primary_key = 'user_id'
      end

      expect(klass.table_primary_key).to eq(%w[user_id])
    end
  end

  describe '.table_columns' do
    it 'returns all column names from the ClickHouse schema cache' do
      klass = described_class.build { self.table_name = 'agent_platform_sessions' }

      expect(klass.table_columns).to include('namespace_path', 'user_id', 'session_id', 'flow_type',
        'created_event_at', 'finished_event_at')
    end

    it 'raises when `table_name` is not set' do
      klass = described_class.build {} # rubocop:disable Lint/EmptyBlock -- block is required

      expect { klass.table_columns }.to raise_error(ArgumentError, /`table_name` must be set/)
    end
  end

  describe 'with deduplication' do
    include ClickHouseHelpers

    let(:finished_at) { Arel.sql("parseDateTime64BestEffort('2024-01-01 00:00:00', 6, 'UTC')") }
    let(:version_old) { Arel.sql("parseDateTime64BestEffort('2024-01-01 00:00:00', 6, 'UTC')") }
    let(:version_new) { Arel.sql("parseDateTime64BestEffort('2024-01-01 01:00:00', 6, 'UTC')") }

    # Two rows with the same primary key (status, runner_type, project_id, finished_at, id),
    # different version timestamps - dedup should pick the newer one (build1_v2).
    let(:build1_v1) do
      { id: 1, status: 'success', runner_type: 0, project_id: 100, finished_at: finished_at, version: version_old,
        deleted: false, name: 'build1_v1' }
    end

    let(:build1_v2) do
      { id: 1, status: 'success', runner_type: 0, project_id: 100, finished_at: finished_at, version: version_new,
        deleted: false, name: 'build1_v2' }
    end

    # Deleted row - should be excluded after deduplication.
    let(:build2_deleted) do
      { id: 2, status: 'success', runner_type: 0, project_id: 100, finished_at: finished_at, version: version_old,
        deleted: true, name: 'build2_del' }
    end

    # Normal row in a different project.
    let(:build3) do
      { id: 3, status: 'success', runner_type: 0, project_id: 200, finished_at: finished_at, version: version_old,
        deleted: false, name: 'build3' }
    end

    let(:dedup_engine_definition) do
      described_class.build do
        self.table_name = 'ci_finished_builds'

        versioned_by :version, deleted_marker: :deleted

        filters do
          exact_match :project_id, :integer
          exact_match :name, :string
        end

        dimensions do
          column :project_id, :integer
          column :name, :string
        end

        metrics do
          count
        end
      end
    end

    let(:dedup_engine) do
      dedup_engine_definition.new(context: { scope: ClickHouse::Client::QueryBuilder.new('ci_finished_builds') })
    end

    before do
      rows = [build1_v1, build1_v2, build2_deleted, build3]
      clickhouse_fixture(:ci_finished_builds, rows.map do |r|
        r.slice(:id, :status, :runner_type, :project_id, :finished_at, :version, :deleted, :name)
      end)
    end

    it 'deduplicates rows by version and excludes deleted records' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :project_id }],
        metrics: [{ identifier: :total_count }]
      )

      expect(dedup_engine).to execute_aggregation(request).and_return(match_array([
        { project_id: 100, total_count: 1 },
        { project_id: 200, total_count: 1 }
      ]))
    end

    it 'returns the latest-version value for deduplicated rows' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :name }],
        metrics: [{ identifier: :total_count }]
      )

      expect(dedup_engine).to execute_aggregation(request).and_return(match_array([
        { name: 'build1_v2', total_count: 1 },
        { name: 'build3', total_count: 1 }
      ]))
    end

    it 'applies PK filters on raw data before deduplication' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :project_id, values: [100] }],
        dimensions: [{ identifier: :project_id }],
        metrics: [{ identifier: :total_count }]
      )

      # Only build1_v2 survives (build1_v1 deduplicated, build2_deleted filtered)
      expect(dedup_engine).to execute_aggregation(request).and_return([
        { project_id: 100, total_count: 1 }
      ])
    end

    it 'applies non-PK filters after deduplication so they see argMax-resolved values' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :name, values: ['build1_v2'] }],
        dimensions: [{ identifier: :project_id }],
        metrics: [{ identifier: :total_count }]
      )

      # The old version value 'build1_v1' is gone after dedup; only 'build1_v2' matches.
      expect(dedup_engine).to execute_aggregation(request).and_return([
        { project_id: 100, total_count: 1 }
      ])
    end

    it 'returns nothing when filtering by a superseded (old-version) non-PK value' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :name, values: ['build1_v1'] }],
        dimensions: [{ identifier: :project_id }],
        metrics: [{ identifier: :total_count }]
      )

      expect(dedup_engine).to execute_aggregation(request).and_return([])
    end

    context 'without deleted_marker' do
      let(:dedup_engine_definition) do
        described_class.build do
          self.table_name = 'ci_finished_builds'

          versioned_by :version

          filters do
            exact_match :project_id, :integer
          end

          dimensions do
            column :project_id, :integer
          end

          metrics do
            count
          end
        end
      end

      it 'deduplicates rows by version without filtering deleted records' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :project_id }],
          metrics: [{ identifier: :total_count }]
        )

        # All 3 unique PKs survive (build1_v1/v2 deduplicated, build2_deleted kept since no deleted_marker)
        expect(dedup_engine).to execute_aggregation(request).and_return(match_array([
          { project_id: 100, total_count: 2 },
          { project_id: 200, total_count: 1 }
        ]))
      end
    end
  end

  describe "window metrics query wrapping" do
    let(:engine_definition) do
      described_class.build do
        self.table_name = 'agent_platform_sessions'

        dimensions do
          column :user_id, :integer
        end

        metrics do
          count
          retained_count :returning_users, :integer, -> { Arel.sql('user_id') }, over: :user_id
        end
      end
    end

    it 'generates query with window wrapper when window metrics are requested' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :returning_users_count }]
      )

      plan = request.to_query_plan(engine)
      aggregation_result = engine.send(:execute_query_plan, plan)

      expect(aggregation_result.send(:query).to_sql).to include('ch_aggregation_window_query')
    end

    it 'generates query without window wrapper when no window metrics are requested' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :total_count }]
      )

      plan = request.to_query_plan(engine)
      aggregation_result = engine.send(:execute_query_plan, plan)

      expect(aggregation_result.send(:query).to_sql).not_to include('ch_aggregation_window_query')
    end

    it 'applies ORDER BY after the window wrapper query' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :returning_users_count }],
        order: [{ identifier: :user_id, direction: :asc }]
      )

      plan = request.to_query_plan(engine)
      aggregation_result = engine.send(:execute_query_plan, plan)
      sql = aggregation_result.send(:query).to_sql

      expect(sql).to match(/ch_aggregation_window_query.*ORDER BY.*aeq_user_id.*ASC/m)
    end

    it 'replaces window metric alias with window SQL in windowed projections' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :returning_users_count }]
      )

      plan = request.to_query_plan(engine)
      aggregation_result = engine.send(:execute_query_plan, plan)
      sql = aggregation_result.send(:query).to_sql

      expect(sql).to include('arrayIntersect')
      expect(sql).to include('length(')
      expect(sql).to include('lagInFrame')
      expect(sql).to include('aeq_returning_users_count')
    end

    it 'passes non-window metric aliases through unchanged in windowed projections' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :total_count }, { identifier: :returning_users_count }]
      )

      plan = request.to_query_plan(engine)
      aggregation_result = engine.send(:execute_query_plan, plan)
      sql = aggregation_result.send(:query).to_sql

      # non-window metric alias is a plain column reference, not wrapped in bitmap SQL
      expect(sql).to include('aeq_total_count')
      expect(sql).not_to match(/bitmap\w+\([^,]*aeq_total_count/)
    end

    context 'with lagged_count metric type' do
      let(:engine_definition) do
        described_class.build do
          self.table_name = 'agent_platform_sessions'

          dimensions do
            column :user_id, :integer
          end

          metrics do
            lagged_count :previous_users, :integer, -> { Arel.sql('user_id') }, over: :user_id
          end
        end
      end

      it 'generates lag window SQL for lagged_count metric' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_id }],
          metrics: [{ identifier: :previous_users_count }]
        )

        plan = request.to_query_plan(engine)
        aggregation_result = engine.send(:execute_query_plan, plan)
        sql = aggregation_result.send(:query).to_sql

        expect(sql).to include('lagInFrame')
        expect(sql).not_to include('bitmapCardinality')
        expect(sql).not_to include('finalizeAggregation')
        expect(sql).not_to include('arrayIntersect')
      end
    end

    context 'with multiple window metrics' do
      let(:engine_definition) do
        described_class.build do
          self.table_name = 'agent_platform_sessions'

          dimensions do
            column :user_id, :integer
          end

          metrics do
            retained_count :returning_users, :integer, -> { Arel.sql('user_id') }, over: :user_id
            lagged_count :previous_users, :integer, -> { Arel.sql('user_id') }, over: :user_id
          end
        end
      end

      it 'wraps all window metrics in the window query' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_id }],
          metrics: [{ identifier: :returning_users_count }, { identifier: :previous_users_count }]
        )

        plan = request.to_query_plan(engine)
        aggregation_result = engine.send(:execute_query_plan, plan)
        sql = aggregation_result.send(:query).to_sql

        expect(sql).to include('arrayIntersect')
        expect(sql).to include('lagInFrame')
        expect(sql).to include('aeq_returning_users_count')
        expect(sql).to include('aeq_previous_users_count')
      end
    end

    context 'with filter, order, and pagination applied' do
      let(:engine_definition) do
        described_class.build do
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
            retained_count :returning_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
          end
        end
      end

      let(:request) do
        Gitlab::Database::Aggregation::Request.new(
          filters: [{ identifier: :flow_type, values: ['chat'] }],
          dimensions: [{ identifier: :event_date, parameters: { granularity: 'daily' } }],
          metrics: [{ identifier: :returning_users_count }],
          order: [{ identifier: :event_date, parameters: { granularity: 'daily' }, direction: :desc }]
        )
      end

      let(:paginated_sql) do
        response = engine.execute(request)
        response.payload[:data].limit(10).offset(20).send(:query).to_sql
      end

      it 'nests filter on inner aggregation, order and pagination on outer window query' do
        sql = paginated_sql

        expect(sql).to include('ch_aggregation_inner_query')
        expect(sql).to include('ch_aggregation_finalized_query')
        expect(sql).to include('ch_aggregation_window_query')

        expect(sql)
        .to match(/WHERE\s+`agent_platform_sessions`\.`flow_type`\s+IN\s+\('chat'\).*ch_aggregation_inner_query/m)

        expect(sql).to include('arrayIntersect')
        expect(sql).to include('lagInFrame(aeq_returning_users_count, 1, [])')
        expect(sql).to include('OVER (ORDER BY aeq_event_date_daily ASC)')

        expect(sql).to match(/ch_aggregation_window_query.*ORDER BY.*aeq_event_date_daily.*DESC/m)
        expect(sql).to match(/LIMIT\s+10/)
        expect(sql).to match(/OFFSET\s+20/)
      end
    end
  end
end

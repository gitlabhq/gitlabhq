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
        mean :duration, :float, ->(_params) {
          Arel.sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))")
        }
        quantile :duration, :float,
          ->(_params) { Arel.sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))") },
          parameters: { quantile: { type: :float } }
        count :with_format, :integer, nil, formatter: ->(v) { v * -1 }
        mean :"duration.mean", :float, ->(_params) {
          Arel.sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))")
        }
        quantile :"duration.quantile", :float,
          ->(_params) { Arel.sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))") },
          parameters: { quantile: { type: :float } }
        mean :"session_year.mean", :float
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

  describe "dotted metric identifiers" do
    it 'aggregates dotted metrics and returns sanitized result keys' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :"duration.mean" }],
        order: [{ identifier: :"duration.mean", direction: :desc }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { user_id: 1, duration__mean: 510.0 },
        { user_id: 2, duration__mean: 180.0 }
      ])
    end

    context 'when no expression is given' do
      let(:request) do
        Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_id }],
          metrics: [{ identifier: :"session_year.mean" }],
          order: [{ identifier: :user_id, direction: :asc }]
        )
      end

      it 'falls back to the first-segment column' do
        expect(engine).to execute_aggregation(request).and_return([
          { user_id: 1, session_year__mean: 2025.0 },
          { user_id: 2, session_year__mean: 2025.0 }
        ])
      end
    end

    it 'supports parameterized dotted metrics alongside flat metrics' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [
          { identifier: :total_count },
          { identifier: :"duration.quantile", parameters: { quantile: 0.9 } }
        ],
        order: [{ identifier: :user_id, direction: :asc }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { user_id: 1, total_count: 4, duration__quantile_8139b: 582.0 },
        { user_id: 2, total_count: 1, duration__quantile_8139b: 180.0 }
      ])
    end
  end

  describe "measurement macro" do
    let(:engine_definition) do
      described_class.build do
        self.table_name = 'agent_platform_sessions'

        transient(:duration) do
          sql("dateDiff('seconds', anyIfMerge(created_event_at), anyIfMerge(finished_event_at))")
        end

        dimensions do
          column :user_id, :integer
        end

        measurement :duration, :integer, transient(:duration), description: 'Session duration in seconds'
      end
    end

    it 'aggregates all measurement aggregates in one request' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [
          { identifier: :"duration.min" },
          { identifier: :"duration.max" },
          { identifier: :"duration.mean" },
          { identifier: :"duration.quantile", parameters: { quantile: 0.5 } }
        ],
        order: [{ identifier: :user_id, direction: :asc }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { user_id: 1, duration__min: 420, duration__max: 600, duration__mean: 510.0,
          duration__quantile_d2cba: 510.0 },
        { user_id: 2, duration__min: 180, duration__max: 180, duration__mean: 180.0,
          duration__quantile_d2cba: 180.0 }
      ])
    end

    it 'rejects quantile values outside the declared bounds' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :"duration.quantile", parameters: { quantile: 1.5 } }]
      )

      response = engine.execute(request)

      expect(response).to be_error
      expect(response.message).to include('Invalid value(s) for parameter `quantile`')
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

    it 'returns results when window metrics are requested' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :returning_users_count }]
      )

      expect(engine).to execute_aggregation(request).and_return(match_array([
        { user_id: 1, returning_users_count: 0 },
        { user_id: 2, returning_users_count: 0 }
      ]))
    end

    it 'returns correct aggregation results when only regular metrics are requested' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :total_count }]
      )

      expect(engine).to execute_aggregation(request).and_return(match_array([
        { user_id: 1, total_count: 4 },
        { user_id: 2, total_count: 1 }
      ]))
    end

    it 'orders window metric results by the specified dimension and computes integer intersection values' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :returning_users_count }],
        order: [{ identifier: :user_id, direction: :asc }]
      )

      expect(engine).to execute_aggregation(request).and_return([
        { user_id: 1, returning_users_count: 0 },
        { user_id: 2, returning_users_count: 0 }
      ])
    end

    it 'returns both regular and window metrics when mixed' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_id }],
        metrics: [{ identifier: :total_count }, { identifier: :returning_users_count }]
      )

      expect(engine).to execute_aggregation(request).and_return(match_array([
        { user_id: 1, total_count: 4, returning_users_count: 0 },
        { user_id: 2, total_count: 1, returning_users_count: 0 }
      ]))
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

      it 'returns previous period user counts using lag window logic' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_id }],
          metrics: [{ identifier: :previous_users_count }],
          order: [{ identifier: :user_id, direction: :asc }]
        )

        # user_id=1 is the first group (no prior) so lag=0; user_id=2 sees prior count of 1
        expect(engine).to execute_aggregation(request).and_return([
          { user_id: 1, previous_users_count: 0 },
          { user_id: 2, previous_users_count: 1 }
        ])
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

      it 'computes both window metrics together' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_id }],
          metrics: [{ identifier: :returning_users_count }, { identifier: :previous_users_count }],
          order: [{ identifier: :user_id, direction: :asc }]
        )

        expect(engine).to execute_aggregation(request).and_return([
          { user_id: 1, returning_users_count: 0, previous_users_count: 0 },
          { user_id: 2, returning_users_count: 0, previous_users_count: 1 }
        ])
      end
    end

    context 'with non-over dimensions' do
      let(:engine_definition) do
        described_class.build do
          self.table_name = 'agent_platform_sessions'

          dimensions do
            column :flow_type, :string
            date_bucket :event_date, :date, -> { Arel.sql('anyIfMerge(created_event_at)') }, parameters: {
              granularity: { type: :string, in: %w[daily] }
            }
          end

          metrics do
            retained_count :returning_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
            lagged_count :previous_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
          end
        end
      end

      it 'returns window metrics partitioned correctly by non-over dimension' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [
            { identifier: :flow_type },
            { identifier: :event_date, parameters: { granularity: 'daily' } }
          ],
          metrics: [
            { identifier: :returning_users_count },
            { identifier: :previous_users_count }
          ],
          order: [{ identifier: :event_date, parameters: { granularity: 'daily' }, direction: :asc }]
        )

        # Window is PARTITION BY flow_type ORDER BY event_date ASC.
        # user 1 reappears on 2025-04-04 after 2025-03-04, so retained count = 1 on that date.
        expect(engine).to execute_aggregation(request).and_return([
          { flow_type: 'chat', event_date_daily: Date.parse('2025-03-01'), returning_users_count: 0,
            previous_users_count: 0 },
          { flow_type: 'chat', event_date_daily: Date.parse('2025-03-02'), returning_users_count: 0,
            previous_users_count: 1 },
          { flow_type: 'chat', event_date_daily: Date.parse('2025-03-04'), returning_users_count: 0,
            previous_users_count: 1 },
          { flow_type: 'chat', event_date_daily: Date.parse('2025-04-04'), returning_users_count: 1,
            previous_users_count: 1 }
        ])
      end
    end

    context 'with all bitmap metrics over a date bucket' do
      let(:engine_definition) do
        described_class.build do
          self.table_name = 'agent_platform_sessions'

          dimensions do
            column :flow_type, :string
            date_bucket :event_date, :date, -> { Arel.sql('anyIfMerge(created_event_at)') }, parameters: {
              granularity: { type: :string, in: %w[daily] }
            }
          end

          metrics do
            count :distinct_users, :integer, -> { Arel.sql('user_id') }, distinct: true
            retained_count :returning_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
            lagged_count :previous_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
            acquired_count :new_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
            churned_count :churned_users, :integer, -> { Arel.sql('user_id') }, over: :event_date
          end
        end
      end

      let(:request) do
        Gitlab::Database::Aggregation::Request.new(
          dimensions: [
            { identifier: :flow_type },
            { identifier: :event_date, parameters: { granularity: 'daily' } }
          ],
          metrics: [
            { identifier: :distinct_users_count },
            { identifier: :returning_users_count },
            { identifier: :previous_users_count },
            { identifier: :new_users_count },
            { identifier: :churned_users_count }
          ],
          order: [{ identifier: :event_date, parameters: { granularity: 'daily' }, direction: :asc }]
        )
      end

      # 2025-03-04 holds two rows for user 1 (sessions 3 and 4), so groupArray yields [1, 1]
      # there. Without arrayDistinct, new_users_count on that date would be 2 instead of 1.
      it 'computes acquired and churned counts alongside the existing bitmap metrics' do
        expect(engine).to execute_aggregation(request).and_return([
          { flow_type: 'chat', event_date_daily: Date.parse('2025-03-01'), distinct_users_count: 1,
            returning_users_count: 0, previous_users_count: 0, new_users_count: 1, churned_users_count: 0 },
          { flow_type: 'chat', event_date_daily: Date.parse('2025-03-02'), distinct_users_count: 1,
            returning_users_count: 0, previous_users_count: 1, new_users_count: 1, churned_users_count: 1 },
          { flow_type: 'chat', event_date_daily: Date.parse('2025-03-04'), distinct_users_count: 1,
            returning_users_count: 0, previous_users_count: 1, new_users_count: 1, churned_users_count: 1 },
          { flow_type: 'chat', event_date_daily: Date.parse('2025-04-04'), distinct_users_count: 1,
            returning_users_count: 1, previous_users_count: 1, new_users_count: 0, churned_users_count: 0 }
        ])
      end

      it 'satisfies the retained/acquired and retained/churned identities per bucket',
        :aggregate_failures do
        rows = engine.execute(request)[:data].to_a.map(&:with_indifferent_access)

        expect(rows).not_to be_empty

        rows.each do |row|
          expect(row[:returning_users_count] + row[:new_users_count]).to eq(row[:distinct_users_count])
          expect(row[:returning_users_count] + row[:churned_users_count]).to eq(row[:previous_users_count])
        end
      end
    end

    context 'with acquired_count as the only metric' do
      let(:engine_definition) do
        described_class.build do
          self.table_name = 'agent_platform_sessions'

          dimensions do
            column :user_id, :integer
          end

          metrics do
            acquired_count :new_users, :integer, -> { Arel.sql('user_id') }, over: :user_id
          end
        end
      end

      it 'returns acquired user counts using difference window logic' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_id }],
          metrics: [{ identifier: :new_users_count }],
          order: [{ identifier: :user_id, direction: :asc }]
        )

        # Each user_id group holds only itself, and no group repeats the previous one,
        # so every group acquires exactly one value.
        expect(engine).to execute_aggregation(request).and_return([
          { user_id: 1, new_users_count: 1 },
          { user_id: 2, new_users_count: 1 }
        ])
      end
    end

    context 'with churned_count as the only metric' do
      let(:engine_definition) do
        described_class.build do
          self.table_name = 'agent_platform_sessions'

          dimensions do
            column :user_id, :integer
          end

          metrics do
            churned_count :churned_users, :integer, -> { Arel.sql('user_id') }, over: :user_id
          end
        end
      end

      it 'returns churned user counts using reverse difference window logic' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_id }],
          metrics: [{ identifier: :churned_users_count }],
          order: [{ identifier: :user_id, direction: :asc }]
        )

        # user_id=1 is the first group so nothing can have churned; user_id=2 loses user 1.
        expect(engine).to execute_aggregation(request).and_return([
          { user_id: 1, churned_users_count: 0 },
          { user_id: 2, churned_users_count: 1 }
        ])
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

      it 'applies filter, order, and pagination to window metric results' do
        # All 5 sessions are flow_type=chat; 4 distinct event dates ordered DESC.
        # user 1 reappears on 2025-04-04 after 2025-03-04, so retained = 1 on that date.
        expect(engine).to execute_aggregation(request).and_return([
          { event_date_daily: Date.parse('2025-04-04'), returning_users_count: 1 },
          { event_date_daily: Date.parse('2025-03-04'), returning_users_count: 0 },
          { event_date_daily: Date.parse('2025-03-02'), returning_users_count: 0 },
          { event_date_daily: Date.parse('2025-03-01'), returning_users_count: 0 }
        ])

        paginated = engine.execute(request).payload[:data].limit(2).offset(0).to_a
        expect(paginated.size).to eq(2)
      end
    end
  end

  describe 'supporting CTEs' do
    include ClickHouseHelpers

    let(:cte_engine_definition) do
      described_class.build do
        self.table_name = 'duo_workflows_workflows_enriched'

        supporting_cte :user_activity, join_key: :user_id do |qb|
          qb.select(
            qb.count.as('workflows'),
            qb.named_func('uniqExact', [qb[:workflow_definition]]).as('flow_types'),
            qb.named_func('uniqExact', [qb.named_func('toDate', [qb[:created_at]])]).as('active_days')
          )
        end

        supporting_cte :user_credits, join_key: :user_id do |qb|
          qb.select(qb.named_func('sum', [qb[:credits_used]]).as('credits'))
        end

        dimensions do
          column :user_id, :integer
          column :user_tier, :string, -> {
            sql("multiIf(user_activity.workflows >= 5, 'heavy', user_activity.workflows >= 2, 'medium', 'light')")
          }, ctes: [:user_activity]
        end

        filters do
          exact_match :workflow_definition, :string
          range :flow_types_used, :integer, -> { sql('user_activity.flow_types') }, ctes: :user_activity
          range :active_days, :integer, -> { sql('user_activity.active_days') }, ctes: [:user_activity]
          range :credits_used, :float, -> { sql('user_credits.credits') }, ctes: [:user_credits]
        end

        metrics do
          count
          count :users, :integer, -> { sql('user_id') }, distinct: true
          count :heavy_users, :integer,
            -> { sql('multiIf(user_activity.workflows >= 5, user_id, NULL)') },
            distinct: true, ctes: [:user_activity]
        end
      end
    end

    let(:cte_engine) do
      cte_engine_definition.new(
        context: { scope: ClickHouse::Client::QueryBuilder.new('duo_workflows_workflows_enriched') }
      )
    end

    let(:version_old) { '2025-03-31 00:00:00' }
    let(:version_new) { '2025-04-01 00:00:00' }

    # user 1: 6 workflows, 3 flow types, 3 active days, 6.0 credits => heavy
    # user 2: 3 workflows, 2 flow types, 2 active days, 1.5 credits => medium
    # user 3: 1 workflow, 1 flow type, 1 active day, 0.0 credits => light
    let(:workflow_rows) do
      [
        # Superseded version: latest flow is software_development, not chat.
        workflow_row(id: 1, user_id: 1, created_on: '2025-03-01', flow: 'chat', credits: 1.0, version: version_old),
        workflow_row(id: 1, user_id: 1, created_on: '2025-03-01', flow: 'software_development', credits: 1.0),
        workflow_row(id: 2, user_id: 1, created_on: '2025-03-01', flow: 'software_development', credits: 1.0),
        workflow_row(id: 3, user_id: 1, created_on: '2025-03-02', flow: 'convert_to_gitlab_ci', credits: 1.0),
        workflow_row(id: 4, user_id: 1, created_on: '2025-03-02', flow: 'chat', credits: 1.0),
        workflow_row(id: 5, user_id: 1, created_on: '2025-03-03', flow: 'chat', credits: 1.0),
        workflow_row(id: 6, user_id: 1, created_on: '2025-03-03', flow: 'chat', credits: 1.0),
        workflow_row(id: 7, user_id: 2, created_on: '2025-03-01', flow: 'software_development', credits: 0.5),
        workflow_row(id: 8, user_id: 2, created_on: '2025-03-01', flow: 'chat', credits: 0.5),
        workflow_row(id: 9, user_id: 2, created_on: '2025-03-05', flow: 'chat', credits: 0.5),
        # Superseded version: if dedup leaked into the CTE, user 3 would have 2 flow types.
        workflow_row(id: 10, user_id: 3, created_on: '2025-03-04', flow: 'software_development',
          version: version_old),
        workflow_row(id: 10, user_id: 3, created_on: '2025-03-04', flow: 'chat'),
        # Deleted: if it leaked into the CTE, user 3 would have 2 active days and 5.0 credits.
        workflow_row(id: 11, user_id: 3, created_on: '2025-03-06', flow: 'chat', credits: 5.0, deleted: true)
      ]
    end

    before do
      clickhouse_fixture(:duo_workflows_workflows_enriched, workflow_rows)
    end

    def workflow_row(id:, user_id:, created_on:, flow:, credits: 0.0, version: nil, deleted: false)
      {
        id: id,
        user_id: user_id,
        traversal_path: '1/2/',
        created_at: datetime64("#{created_on} 00:00:00"),
        workflow_definition: flow,
        credits_used: credits,
        _siphon_deleted: deleted,
        _version: datetime64(version || version_new)
      }
    end

    def datetime64(value)
      Arel.sql("parseDateTime64BestEffort('#{value}', 6, 'UTC')")
    end

    it 'splits rows and users by a CTE-backed tier dimension' do
      request = Gitlab::Database::Aggregation::Request.new(
        dimensions: [{ identifier: :user_tier }],
        metrics: [{ identifier: :total_count }, { identifier: :users_count }],
        order: [{ identifier: :user_tier, direction: :asc }]
      )

      expect(cte_engine).to execute_aggregation(request).and_return([
        { user_tier: 'heavy', total_count: 6, users_count: 1 },
        { user_tier: 'light', total_count: 1, users_count: 1 },
        { user_tier: 'medium', total_count: 3, users_count: 1 }
      ])
    end

    it 'counts users matching a per-user condition as a single-number query' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :flow_types_used, values: 2..nil }],
        metrics: [{ identifier: :users_count }]
      )

      expect(cte_engine).to execute_aggregation(request).and_return([
        { users_count: 2 }
      ])
    end

    it 'counts users active on exactly one day, ignoring superseded and deleted rows' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :active_days, values: 1..1 }],
        metrics: [{ identifier: :users_count }]
      )

      expect(cte_engine).to execute_aggregation(request).and_return([
        { users_count: 1 }
      ])
    end

    it 'propagates row filters into the CTE so tiers reflect the filtered scope' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :workflow_definition, values: ['chat'] }],
        dimensions: [{ identifier: :user_tier }],
        metrics: [{ identifier: :total_count }, { identifier: :users_count }],
        order: [{ identifier: :user_tier, direction: :asc }]
      )

      # After the chat filter, user 1 has 3 chat workflows and drops from heavy to medium.
      expect(cte_engine).to execute_aggregation(request).and_return([
        { user_tier: 'light', total_count: 1, users_count: 1 },
        { user_tier: 'medium', total_count: 5, users_count: 2 }
      ])
    end

    it 'combines multiple distinct CTEs in one query' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :credits_used, values: 2.0..nil }],
        dimensions: [{ identifier: :user_tier }],
        metrics: [{ identifier: :users_count }]
      )

      expect(cte_engine).to execute_aggregation(request).and_return([
        { user_tier: 'heavy', users_count: 1 }
      ])
    end

    it 'supports CTE-backed metrics' do
      request = Gitlab::Database::Aggregation::Request.new(
        metrics: [{ identifier: :heavy_users_count }]
      )

      expect(cte_engine).to execute_aggregation(request).and_return([
        { heavy_users_count: 1 }
      ])
    end

    it 'builds and joins a CTE once when multiple parts reference it' do
      request = Gitlab::Database::Aggregation::Request.new(
        filters: [{ identifier: :flow_types_used, values: 1..nil }],
        dimensions: [{ identifier: :user_tier }],
        metrics: [{ identifier: :heavy_users_count }]
      )

      response = cte_engine.execute(request)
      sql = response.payload[:data].send(:query).to_sql

      expect(sql.scan('user_activity AS (').size).to eq(1)
      expect(sql.scan('JOIN `user_activity`').size).to eq(1)
    end

    context 'with join_type: :outer' do
      let(:cte_engine_definition) do
        described_class.build do
          self.table_name = 'duo_workflows_workflows_enriched'

          supporting_cte :user_activity, join_key: :user_id, join_type: :outer do |qb|
            qb.select(qb.count.as('workflows'))
          end

          dimensions do
            column :user_workflows, :integer, -> { sql('user_activity.workflows') }, ctes: [:user_activity]
          end

          metrics do
            count :users, :integer, -> { sql('user_id') }, distinct: true
          end
        end
      end

      it 'renders a LEFT OUTER JOIN and returns correct results' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_workflows }],
          metrics: [{ identifier: :users_count }],
          order: [{ identifier: :user_workflows, direction: :asc }]
        )

        response = cte_engine.execute(request)

        expect(response.payload[:data].send(:query).to_sql).to include('LEFT OUTER JOIN `user_activity`')
        expect(response.payload[:data].to_a).to eq([
          { 'user_workflows' => 1, 'users_count' => 1 },
          { 'user_workflows' => 3, 'users_count' => 1 },
          { 'user_workflows' => 6, 'users_count' => 1 }
        ])
      end
    end

    describe 'definition-time validation' do
      it 'raises when a dimension references an undeclared CTE' do
        expect do
          described_class.build do
            self.table_name = 'duo_workflows_workflows_enriched'

            dimensions do
              column :user_tier, :string, -> { sql('user_activity.workflows') }, ctes: [:user_activity]
            end
          end
        end.to raise_error(ArgumentError, /Unknown supporting CTE\(s\) \[:user_activity\]/)
      end

      it 'raises when a filter references an undeclared CTE' do
        expect do
          described_class.build do
            self.table_name = 'duo_workflows_workflows_enriched'

            filters do
              range :flow_types_used, :integer, -> { sql('user_activity.flow_types') }, ctes: :user_activity
            end
          end
        end.to raise_error(ArgumentError, /Unknown supporting CTE\(s\) \[:user_activity\]/)
      end

      it 'raises when a metric references an undeclared CTE' do
        expect do
          described_class.build do
            self.table_name = 'duo_workflows_workflows_enriched'

            metrics do
              count :heavy_users, :integer, -> { sql('user_id') }, distinct: true, ctes: [:user_activity]
            end
          end
        end.to raise_error(ArgumentError, /Unknown supporting CTE\(s\) \[:user_activity\]/)
      end

      it 'raises for tables with unsupported table engines' do
        expect do
          described_class.build do
            self.table_name = 'agent_platform_sessions'

            supporting_cte(:user_activity, join_key: :user_id) { |qb| qb }
          end
        end.to raise_error(ArgumentError, /not supported for AggregatingMergeTree tables/)
      end

      it 'raises when `table_name` is not set' do
        expect do
          described_class.build do
            supporting_cte(:user_activity, join_key: :user_id) { |qb| qb }
          end
        end.to raise_error(ArgumentError, /`table_name` must be set/)
      end

      it 'raises when the join_key is not a table column' do
        expect do
          described_class.build do
            self.table_name = 'duo_workflows_workflows_enriched'

            supporting_cte(:user_activity, join_key: :unknown_column) { |qb| qb }
          end
        end.to raise_error(ArgumentError, /Unknown `join_key` column `unknown_column`/)
      end

      it 'raises for duplicate CTE names' do
        expect do
          described_class.build do
            self.table_name = 'duo_workflows_workflows_enriched'

            supporting_cte(:user_activity, join_key: :user_id) { |qb| qb }
            supporting_cte(:user_activity, join_key: :user_id) { |qb| qb }
          end
        end.to raise_error(ArgumentError, /`user_activity` is already declared/)
      end

      it 'raises for an invalid join_type' do
        expect do
          described_class.build do
            self.table_name = 'duo_workflows_workflows_enriched'

            supporting_cte(:user_activity, join_key: :user_id, join_type: :cross) { |qb| qb }
          end
        end.to raise_error(ArgumentError, /Invalid `join_type` `cross`/)
      end

      it 'raises without a block' do
        expect do
          described_class.build do
            self.table_name = 'duo_workflows_workflows_enriched'

            supporting_cte(:user_activity, join_key: :user_id)
          end
        end.to raise_error(ArgumentError, /requires a block/)
      end
    end

    describe 'tier dimension' do
      let(:cte_engine_definition) do
        described_class.build do
          self.table_name = 'duo_workflows_workflows_enriched'

          supporting_cte :user_activity, join_key: :user_id do |qb|
            qb.select(qb.count.as('workflows'))
          end

          dimensions do
            tier :user_tier, :string, -> { sql('user_activity.workflows') }, ctes: [:user_activity]
          end

          metrics do
            count
            count :users, :integer, -> { sql('user_id') }, distinct: true
          end
        end
      end

      it 'buckets values into tiers, with threshold boundaries going to the upper tier' do
        # user 1 has 6 workflows (== last threshold => tier_2),
        # user 2 has 3 (== first threshold => tier_1), user 3 has 1 (< 3 => tier_0).
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_tier, parameters: { thresholds: [3, 6] } }],
          metrics: [{ identifier: :total_count }, { identifier: :users_count }],
          order: [{ identifier: :user_tier, parameters: { thresholds: [3, 6] }, direction: :asc }]
        )

        expect(cte_engine).to execute_aggregation(request).and_return([
          { user_tier_3_6: 'tier_0', total_count: 1, users_count: 1 },
          { user_tier_3_6: 'tier_1', total_count: 3, users_count: 1 },
          { user_tier_3_6: 'tier_2', total_count: 6, users_count: 1 }
        ])
      end

      it 'fails validation when thresholds are missing' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_tier }],
          metrics: [{ identifier: :total_count }]
        )

        expect(cte_engine).to execute_aggregation(request).with_errors([
          a_string_matching(/parameter `thresholds` is required/)
        ])
      end

      it 'fails validation when thresholds are not strictly ascending positive integers' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_tier, parameters: { thresholds: [6, 3] } }],
          metrics: [{ identifier: :total_count }]
        )

        expect(cte_engine).to execute_aggregation(request).with_errors([
          a_string_matching(/parameter `thresholds` must be strictly ascending positive integers/)
        ])
      end

      it 'fails validation when too many thresholds are given' do
        request = Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_tier, parameters: { thresholds: (1..10).to_a } }],
          metrics: [{ identifier: :total_count }]
        )

        expect(cte_engine).to execute_aggregation(request).with_errors([
          a_string_matching(/parameter `thresholds` supports at most 9 values/)
        ])
      end
    end

    context 'with part-level authorization on a CTE-backed dimension' do
      let(:current_user) { build_stubbed(:user) }

      let(:cte_engine_definition) do
        authorized_user = current_user

        described_class.build do
          self.table_name = 'duo_workflows_workflows_enriched'

          supporting_cte :user_activity, join_key: :user_id do |qb|
            qb.select(qb.count.as('workflows'))
          end

          dimensions do
            column :user_tier, :string, -> {
              sql("multiIf(user_activity.workflows >= 5, 'heavy', user_activity.workflows >= 2, 'medium', 'light')")
            }, ctes: [:user_activity], authorize: ->(user, _resources) { user == authorized_user }
          end

          metrics do
            count
          end
        end
      end

      let(:cte_engine) do
        cte_engine_definition.new(
          context: {
            scope: ClickHouse::Client::QueryBuilder.new('duo_workflows_workflows_enriched'),
            current_user: requesting_user,
            authorization_resources: [build_stubbed(:project)]
          }
        )
      end

      let(:request) do
        Gitlab::Database::Aggregation::Request.new(
          dimensions: [{ identifier: :user_tier }],
          metrics: [{ identifier: :total_count }],
          order: [{ identifier: :user_tier, direction: :asc }]
        )
      end

      context 'when the user is authorized' do
        let(:requesting_user) { current_user }

        it 'returns CTE-backed results' do
          expect(cte_engine).to execute_aggregation(request).and_return([
            { user_tier: 'heavy', total_count: 6 },
            { user_tier: 'light', total_count: 1 },
            { user_tier: 'medium', total_count: 3 }
          ])
        end
      end

      context 'when the user is not authorized' do
        let(:requesting_user) { build_stubbed(:user) }

        it 'fails validation for the CTE-backed dimension' do
          expect(cte_engine).to execute_aggregation(request).with_errors([
            a_string_matching(/access to dimension 'user_tier' is not authorized/),
            a_string_matching(/ordering by 'user_tier' is not authorized/)
          ])
        end
      end
    end
  end
end

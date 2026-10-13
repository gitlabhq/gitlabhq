# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::QueryAnalyzers::Capture, query_analyzers: false, feature_category: :database do
  let(:analyzer) { described_class }
  let(:raw) { 'SELECT * FROM users' }
  let(:db_config) { instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, name: 'main_replica') }
  let(:pool) { instance_double(ActiveRecord::ConnectionAdapters::ConnectionPool, db_config: db_config) }
  let(:raw_connection) { instance_double(PG::Connection, backend_pid: 4242) }
  let(:connection) do
    # No raw_connection stub: the analyzer must read the ivar, and the strict
    # double raises if the dirtying public accessor is ever called
    instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, pool: pool).tap do |double|
      double.instance_variable_set(:@raw_connection, raw_connection)
    end
  end

  let(:type_casted_binds) { [] }
  let(:returned_values) { nil }
  let(:parsed) do
    instance_double(
      Gitlab::Database::QueryAnalyzer::Parsed,
      connection: connection,
      raw: raw,
      duration: 1.5,
      type_casted_binds: type_casted_binds,
      returned_values: returned_values
    )
  end

  let(:task) { instance_double(Gitlab::Database::Capture::Task, database_name: 'main') }

  before do
    allow(Gitlab::Runtime).to receive(:application?).and_return(true)
    allow(Process).to receive(:clock_gettime).and_call_original
    allow(Process).to receive(:clock_gettime)
      .with(Process::CLOCK_REALTIME, :millisecond).and_return(1750000000000)
    allow(Process).to receive(:clock_gettime)
      .with(Process::CLOCK_MONOTONIC, :millisecond).and_return(123456)
  end

  after do
    # Clears analyzers list after each test to reload the state of `enabled?` method
    Thread.current[:query_analyzer_enabled_analyzers] = []
  end

  describe '.enabled?' do
    context 'when running in application mode' do
      it 'returns true' do
        expect(analyzer.enabled?).to be true
      end

      context 'when the database_capture feature flag is disabled' do
        before do
          stub_feature_flags(database_capture: false)
        end

        it 'returns false' do
          expect(analyzer.enabled?).to be false
        end
      end

      context 'when the feature flag table is not available' do
        before do
          allow(::Feature::FlipperFeature).to receive(:table_exists?).and_return(false)
        end

        it 'returns false without evaluating the feature flag' do
          expect(::Feature).not_to receive(:enabled?)

          expect(analyzer.enabled?).to be false
        end
      end
    end

    context 'when not running in application mode' do
      before do
        allow(Gitlab::Runtime).to receive(:application?).and_return(false)
      end

      it 'returns false without evaluating the feature flag' do
        expect(Gitlab::Database::Capture).not_to receive(:enabled?)

        expect(analyzer.enabled?).to be false
      end
    end
  end

  describe '.analyze' do
    before do
      allow(Gitlab::Database::Capture::Tasks).to receive(:[]).with('main').and_return(task)
      allow(task).to receive(:push)
    end

    it 'adds the raw query to the appropriate queue' do
      expected_event = {
        'raw' => 'SELECT * FROM users',
        'connection_id' => 4242,
        'timestamp' => 1750000000000,
        'monotonic' => 123456,
        'duration' => 1.5
      }

      expect(task).to receive(:push).with(expected_event)

      analyzer.analyze(parsed)
    end

    it 'extracts the database name correctly' do
      expect(Gitlab::Database::Capture::Tasks).to receive(:[]).with('main').and_return(task)

      analyzer.analyze(parsed)
    end

    context 'when the query has binds and returned values' do
      let(:raw) { 'INSERT INTO users (name) VALUES ($1) RETURNING "id"' }
      let(:type_casted_binds) { ['bob'] }
      let(:returned_values) { { fields: ['id'], values: [[42]] } }

      it 'includes them in the pushed statement' do
        expected_event = {
          'raw' => raw,
          'connection_id' => 4242,
          'timestamp' => 1750000000000,
          'monotonic' => 123456,
          'duration' => 1.5,
          'binds' => ['bob'],
          'returned_values' => { 'fields' => ['id'], 'values' => [[42]] }
        }

        expect(task).to receive(:push).with(expected_event)

        analyzer.analyze(parsed)
      end
    end

    context 'when the query has binary binds' do
      let(:raw) { 'INSERT INTO merge_request_diff_commits (sha) VALUES ($1)' }
      let(:type_casted_binds) do
        [
          { value: "\xDE\xAD\xBE\xEF".b, format: 1 }, # bytea bind: binary-format wire param
          'bob',                                      # regular bind, must pass through
          "\xFF\x01".b                                # stray invalid-UTF-8 string
        ]
      end

      it 'hex-encodes binary values the way the text protocol does' do
        expect(task).to receive(:push).with(hash_including(
          'binds' => ['\xdeadbeef', 'bob', '\xff01']
        ))

        analyzer.analyze(parsed)
      end
    end

    # The flag is only consulted by `.enabled?` when the analyzer is enabled,
    # never from the per-query path.
    it 'does not evaluate the feature flag' do
      expect(Gitlab::Database::Capture).not_to receive(:enabled?)
      expect(::Feature).not_to receive(:enabled?)

      analyzer.analyze(parsed)
    end
  end

  context 'when integrated with QueryAnalyzer' do
    before do
      Gitlab::Database::QueryAnalyzer.instance.begin!([analyzer])
    end

    it 'calls analyze when a query is processed' do
      expect(analyzer).to receive(:analyze)

      process_sql(raw, 'load')
    end
  end

  # Regression test for https://gitlab.com/gitlab-org/gitlab/-/issues/628047:
  # per-query flag evaluation recursed through Flipper's own gate SQL.
  context 'with a real feature flag store', stub_feature_flags: false do
    let(:real_connection) { ApplicationRecord.connection }

    before do
      allow(Gitlab::Database::Capture::Tasks).to receive(:[]).with('main').and_return(task)
      allow(task).to receive(:push)

      real_connection.execute(<<~SQL)
        CREATE TABLE _test_capture_recursion (
          id bigserial PRIMARY KEY,
          name text
        )
      SQL
    end

    after do
      real_connection.execute('DROP TABLE IF EXISTS _test_capture_recursion')
    end

    it 'captures INSERT ... RETURNING without tracking feature flag recursion errors' do
      Feature.enable(:database_capture)
      Gitlab::Database::QueryAnalyzer.instance.begin!([analyzer])

      # Cool the caches warmed by Feature.enable so any flag evaluation during
      # the INSERT must issue gate SQL, as in a fresh process.
      Gitlab::ProcessMemoryCache.cache_backend.clear
      allow(Feature).to receive(:l2_cache_backend).and_return(ActiveSupport::Cache::NullStore.new)
      Feature.reset_flipper

      tracked = []
      allow(Gitlab::ErrorTracking).to receive(:track_exception) { |error, *| tracked << error }

      expect(task).to receive(:push).with(hash_including(
        'raw' => a_string_including("INSERT INTO _test_capture_recursion (name) VALUES ('a') RETURNING id"),
        'returned_values' => { 'fields' => ['id'], 'values' => [[1]] }
      ))

      real_connection.execute("INSERT INTO _test_capture_recursion (name) VALUES ('a') RETURNING id")

      expect(tracked).to be_empty
    end
  end

  private

  def process_sql(sql, event_name)
    Gitlab::Database::QueryAnalyzer.instance.within do
      Gitlab::Database::QueryAnalyzer.instance.send(:process_sql, sql, ActiveRecord::Base.connection, event_name)
    end
  end
end

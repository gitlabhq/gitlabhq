# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::DatabaseInformation, feature_category: :database do
  describe '.execute' do
    subject(:result) { described_class.execute }

    it 'returns a snapshot for the main database by default', :aggregate_failures do
      expect(result[:databases]).to have_key('main')

      payload = result[:databases]['main']
      expect(payload[:current_user]).to be_a(String).and(be_present)
      expect(payload[:search_path]).to be_a(String).and(be_present)
      expect(payload[:schemas]).to be_an(Array).and(be_present)
    end

    it 'excludes system schemas and includes public' do
      schema_names = result[:databases]['main'][:schemas].map { |s| s[:name] }

      expect(schema_names).to include('public')
      expect(schema_names).not_to include('pg_catalog', 'pg_toast', 'information_schema')
    end

    it 'normalizes the current flag to a boolean and flags exactly one schema as current', :aggregate_failures do
      schemas = result[:databases]['main'][:schemas]
      current_schema_name = ApplicationRecord.connection.select_value('SELECT current_schema()')

      schemas.each { |s| expect(s[:current]).to be_in([true, false]) }

      current = schemas.select { |s| s[:current] }
      expect(current.size).to eq(1)
      expect(current.first[:name]).to eq(current_schema_name)
    end

    it 'includes the schema owner for each schema' do
      result[:databases]['main'][:schemas].each do |schema|
        expect(schema[:owner]).to be_a(String).and(be_present)
      end
    end

    it 'includes a findings array' do
      expect(result[:databases]['main'][:findings]).to be_an(Array)
    end

    context 'with search_path findings' do
      let(:model) { class_double(ApplicationRecord) }
      let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
      let(:search_path) { '"$user", public' }
      let(:schema_rows) do
        [{ 'name' => 'public', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }]
      end

      subject(:findings) { described_class.execute[:databases]['main'][:findings] }

      before do
        allow(Gitlab::Database).to receive(:database_base_models).and_return({ 'main' => model })
        allow(model).to receive(:connection).and_return(connection)
        allow(connection).to receive(:select_value).with('SELECT current_user').and_return('gitlab')
        allow(connection).to receive(:select_value).with('SHOW search_path').and_return(search_path)
        allow(connection).to receive(:select_all).and_return(schema_rows)

        # These tests focus on search_path findings; vacuum collection shares
        # collect_for_database but is exercised separately, so stub it out.
        allow_next_instance_of(described_class) do |info|
          allow(info).to receive(:collect_vacuums).and_return([])
        end
      end

      context 'when the search path is the default of "$user", public' do
        it 'returns no findings' do
          expect(findings).to be_empty
        end
      end

      context 'when a partition schema is present in the search path' do
        let(:search_path) { '"$user", public, gitlab_partitions_dynamic' }

        it 'returns only a partition-schema warning', :aggregate_failures do
          codes = findings.map { |f| f[:code] }

          expect(codes).to contain_exactly('search_path_contains_partition_schema')
          expect(findings.first[:severity]).to eq('warning')
        end
      end

      context 'when a populated partition schema is in the search path' do
        let(:search_path) { '"$user", public, gitlab_partitions_dynamic' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab_partitions_dynamic', 'is_current' => false, 'owner' => 'gitlab',
              'has_tables' => true }
          ]
        end

        it 'is flagged only as a partition schema, not as split objects', :aggregate_failures do
          codes = findings.map { |f| f[:code] }

          expect(codes).to include('search_path_contains_partition_schema')
          expect(codes).not_to include('search_path_objects_split_across_schemas')
        end
      end

      context 'when all objects live in a single non-public schema and public is empty' do
        let(:search_path) { 'gitlab, public' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => false },
            { 'name' => 'gitlab', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        it 'returns no findings' do
          expect(findings).to be_empty
        end
      end

      context 'when objects are split across more than one populated schema' do
        let(:search_path) { 'gitlab, public' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        it 'returns a split-objects error naming the schemas', :aggregate_failures do
          finding = findings.find { |f| f[:code] == 'search_path_objects_split_across_schemas' }

          expect(finding).to be_present
          expect(finding[:severity]).to eq('warning')
          expect(finding[:message]).to include('public').and(include('gitlab'))
        end
      end

      context 'when the "$user" token resolves to a populated user schema alongside public' do
        let(:search_path) { '"$user", public' }
        let(:schema_rows) do
          [
            { 'name' => 'public', 'is_current' => false, 'owner' => 'gitlab', 'has_tables' => true },
            { 'name' => 'gitlab', 'is_current' => true, 'owner' => 'gitlab', 'has_tables' => true }
          ]
        end

        it 'resolves "$user" and reports the split' do
          expect(findings.map { |f| f[:code] }).to include('search_path_objects_split_across_schemas')
        end
      end
    end

    context 'with vacuum progress' do
      let(:connection) { Gitlab::Database.database_base_models['main'].connection }
      let(:database_version) { 17_00_04 }
      let(:vacuum_rows) do
        [
          {
            'pid' => '4242',
            'schema_name' => 'public',
            'table_name' => 'ci_builds',
            'phase' => 'vacuuming indexes',
            'heap_blks_total' => '1000',
            'heap_blks_scanned' => '600',
            'heap_blks_vacuumed' => '500',
            'index_vacuum_count' => '2',
            'max_dead_tuple_bytes' => '2097152',
            'dead_tuple_bytes' => '2000000',
            'indexes_total' => '5',
            'indexes_processed' => '3',
            'backend_type' => 'autovacuum worker',
            'activity_query' => 'autovacuum: VACUUM public.ci_builds',
            'running_time_seconds' => '36000',
            'delay_time' => '12.5'
          }
        ]
      end

      subject(:vacuums) { described_class.execute[:databases]['main'][:vacuums] }

      before do
        allow(connection).to receive(:database_version).and_return(database_version)
        allow(connection).to receive(:select_all).and_call_original
        allow(connection).to receive(:select_all)
          .with(a_string_matching(/pg_stat_progress_vacuum/)).and_return(vacuum_rows)
      end

      it 'maps each in-progress vacuum into a typed hash', :aggregate_failures do
        expect(vacuums.size).to eq(1)

        expect(vacuums.first).to include(
          pid: 4242,
          schema_name: 'public',
          table_name: 'ci_builds',
          phase: 'vacuuming indexes',
          heap_blks_total: 1000,
          heap_blks_scanned: 600,
          heap_blks_vacuumed: 500,
          index_vacuum_count: 2,
          max_dead_tuple_bytes: 2097152,
          dead_tuple_bytes: 2000000,
          indexes_total: 5,
          indexes_processed: 3,
          vacuum_type: 'autovacuum',
          anti_wraparound: false,
          running_time_seconds: 36000
        )
      end

      context 'when the vacuum is a manually issued VACUUM' do
        let(:vacuum_rows) do
          [{ 'pid' => '4242', 'backend_type' => 'client backend', 'activity_query' => 'VACUUM ci_builds' }]
        end

        it 'classifies it as manual' do
          expect(vacuums.first).to include(vacuum_type: 'manual', anti_wraparound: false)
        end
      end

      context 'when the vacuum is an anti-wraparound autovacuum' do
        let(:vacuum_rows) do
          [{
            'pid' => '4242',
            'backend_type' => 'autovacuum worker',
            'activity_query' => 'autovacuum: VACUUM public.ci_builds (to prevent wraparound)'
          }]
        end

        it 'flags it as anti-wraparound' do
          expect(vacuums.first).to include(vacuum_type: 'autovacuum', anti_wraparound: true)
        end
      end

      it 'returns an empty array when no vacuum is running' do
        allow(connection).to receive(:select_all)
          .with(a_string_matching(/pg_stat_progress_vacuum/)).and_return([])

        expect(vacuums).to eq([])
      end

      context 'on PostgreSQL 18 and newer' do
        let(:database_version) { 18_00_00 }

        it 'selects and casts delay_time', :aggregate_failures do
          expect(vacuums.first[:delay_time]).to eq(12.5)
          expect(connection).to have_received(:select_all).with(a_string_matching(/v\.delay_time/))
        end
      end

      context 'on PostgreSQL 17' do
        let(:database_version) { 17_00_04 }
        let(:vacuum_rows) do
          [{ 'pid' => '4242', 'phase' => 'scanning heap', 'index_vacuum_count' => '0' }]
        end

        it 'omits the delay_time column and reports nil', :aggregate_failures do
          expect(vacuums.first[:delay_time]).to be_nil
          expect(connection).not_to have_received(:select_all).with(a_string_matching(/v\.delay_time/))
        end
      end
    end

    context 'when a database name does not map to a known model' do
      subject(:result) { described_class.execute(database_names: %w[bogus]) }

      it 'returns an error payload for that database' do
        expect(result[:databases]['bogus']).to eq(error: 'Unknown database: bogus')
      end
    end

    context 'when the connection raises an error' do
      let(:failing_model) { class_double(ApplicationRecord) }
      let(:error) { StandardError.new('PG::ConnectionBad: could not connect to host db.internal:5432') }

      before do
        allow(Gitlab::Database).to receive(:database_base_models)
          .and_return({ 'main' => failing_model })
        allow(failing_model).to receive(:connection).and_raise(error)
      end

      it 'returns a sanitized error payload and tracks the exception', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(error, database_name: 'main')

        expect(result[:databases]['main']).to eq(error: 'Failed to gather information for database: main')
      end
    end
  end
end

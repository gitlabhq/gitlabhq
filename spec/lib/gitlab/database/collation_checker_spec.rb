# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::CollationChecker, feature_category: :database do
  describe '.run' do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
    let(:database_name) { 'main' }
    let(:logger) { instance_double(Gitlab::AppLogger, info: nil, warn: nil, error: nil) }

    it 'instantiates the class and calls run' do
      instance = instance_double(described_class)
      result = { 'collation_mismatches' => [], 'corrupted_indexes' => [] }

      expect(Gitlab::Database::EachDatabase).to receive(:each_connection)
        .with(only: database_name)
        .and_yield(connection, database_name)

      expect(described_class).to receive(:new)
        .with(connection, database_name, logger, described_class::MAX_TABLE_SIZE_FOR_DUPLICATE_CHECK)
        .and_return(instance)
      expect(instance).to receive(:run).and_return(result)

      described_class.run(database_name: database_name, logger: logger)
    end
  end

  describe '#run' do
    # Mock-based tests for edge cases and error handling
    context 'with mocked database connection' do
      let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
      let(:database_name) { 'main' }
      let(:logger) { instance_double(Gitlab::AppLogger, info: nil, warn: nil, error: nil) }
      let(:checker) do
        described_class.new(connection, database_name, logger, described_class::MAX_TABLE_SIZE_FOR_DUPLICATE_CHECK)
      end

      context 'when no collation mismatches are found' do
        let(:empty_results) { instance_double(ActiveRecord::Result, to_a: []) }

        before do
          allow(connection).to receive(:select_all)
            .with(described_class::COLLATION_VERSION_MISMATCH_QUERY)
            .and_return(empty_results)

          allow(checker).to receive_messages(
            transform_indexes_to_spot_check: []
          )
        end

        it 'logs a success message and returns no mismatches or corrupted indexes' do
          expect(logger).to receive(:info).with("Checking for PostgreSQL collation mismatches on main database...")
          expect(logger).to receive(:info).with("Found 0 indexes to corruption spot check.")
          expect(logger).to receive(:info).with(
            "No indexes found for corruption spot check."
          )

          result = checker.run

          expect(result).to eq({ 'collation_mismatches' => [], 'corrupted_indexes' => [], 'skipped_indexes' => [] })
        end
      end

      context 'when collation mismatches exist but no indexes are corrupted' do
        let(:expected_mismatches) do
          [{ 'collation_name' => 'en_US.utf8', 'stored_version' => '1.2.3', 'actual_version' => '1.2.4' }]
        end

        let(:mismatches) do
          instance_double(
            ActiveRecord::Result,
            to_a: expected_mismatches
          )
        end

        before do
          allow(checker).to receive_messages(
            transform_indexes_to_spot_check: ['test_index'],
            fetch_index_info: [],
            identify_corrupted_indexes: []
          )
          allow(connection).to receive(:select_all)
            .with(described_class::COLLATION_VERSION_MISMATCH_QUERY)
            .and_return(mismatches)
        end

        it 'logs warnings about mismatches but reports no corrupted indexes' do
          expect(logger).to receive(:info).with("Checking for PostgreSQL collation mismatches on main database...")
          expect(logger).to receive(:warn).with("Collation mismatches detected on main database!")
          expect(logger).to receive(:warn).with("1 collation(s) have version mismatches:")
          expect(logger).to receive(:warn).with("  - en_US.utf8: stored=1.2.3, actual=1.2.4")

          expect(logger).to receive(:info).with(
            "No corrupted indexes detected."
          )

          result = checker.run

          expect(result).to eq({
            'collation_mismatches' => expected_mismatches,
            'corrupted_indexes' => [],
            'skipped_indexes' => []
          })
        end
      end

      context 'when both collation mismatches and corrupted indexes are found' do
        let(:mismatches) do
          [{ 'collation_name' => 'en_US.utf8', 'stored_version' => '1.2.3', 'actual_version' => '1.2.4' }]
        end

        let(:indexes) do
          [
            {
              'table_name' => 'users',
              'index_name' => 'index_users_on_username'
            }
          ]
        end

        let(:index_info) do
          [
            {
              'table_name' => 'users',
              'index_name' => 'index_users_on_username',
              'affected_columns' => 'username',
              'is_unique' => 't',
              'table_size_bytes' => 10.megabytes,
              'index_size_bytes' => 1.megabyte
            }
          ]
        end

        let(:corrupted_indexes) do
          [
            {
              'index_name' => 'index_users_on_username',
              'table_name' => 'users',
              'affected_columns' => 'username',
              'is_unique' => true,
              'table_size_bytes' => 10.megabytes,
              'index_size_bytes' => 1.megabyte,
              'corruption_types' => ['duplicates'],
              'needs_deduplication' => true
            }
          ]
        end

        before do
          allow(checker).to receive_messages(
            check_collation_mismatches: mismatches,
            transform_indexes_to_spot_check: indexes,
            fetch_index_info: index_info,
            identify_corrupted_indexes: corrupted_indexes
          )
        end

        it 'logs warnings and provides remediation guidance' do
          # Test basic detection
          expect(logger).to receive(:info).with("Checking for PostgreSQL collation mismatches on main database...")
          expect(logger).to receive(:info).with("Found 1 indexes to corruption spot check.")

          # Test corrupted indexes are identified
          expect(logger).to receive(:warn).with("1 corrupted indexes detected!")
          expect(logger).to receive(:warn).with("Affected indexes that need to be rebuilt:")

          # Test index details are logged
          expect(logger).to receive(:warn).with("  - index_users_on_username on table users")
          expect(logger).to receive(:warn).with("    • Issues detected: duplicates")
          expect(logger).to receive(:warn).with("    • Affected columns: username")
          expect(logger).to receive(:warn).with("    • Needs deduplication: Yes")

          # Test remediation header
          expect(logger).to receive(:warn).with("\nREMEDIATION STEPS:")
          expect(logger).to receive(:warn).with("1. Put GitLab into maintenance mode")
          expect(logger).to receive(:warn).with("2. Run the following SQL commands:")

          # Test duplicate entry fixes
          expect(logger).to receive(:warn).with("\n# Step 1: Fix duplicate entries in unique indexes")
          expect(logger).to receive(:warn).with(
            "-- Fix duplicates in users (unique index: index_users_on_username)"
          )
          expect(logger).to receive(:warn) do |message|
            expect(message).to include(
              'SELECT', 'username', 'COUNT(*)', 'FROM users', 'GROUP BY username', 'HAVING COUNT(*) > 1'
            )
          end
          expect(logger).to receive(:warn).with(/\n# Use gitlab:db:deduplicate_tags or similar tasks/)

          # Test index rebuild commands
          expect(logger).to receive(:warn).with("\n# Step 2: Rebuild affected indexes")
          expect(logger).to receive(:warn).with("# Option A: Rebuild individual indexes with minimal downtime:")
          expect(logger).to receive(:warn).with("REINDEX INDEX CONCURRENTLY index_users_on_username;")
          expect(logger).to receive(:warn).with(
            "\n# Option B: Alternatively, rebuild all indexes at once (requires downtime):"
          )
          expect(logger).to receive(:warn).with("REINDEX DATABASE main;")

          # Test collation refresh commands
          expect(logger).to receive(:warn).with("\n# Step 3: Refresh collation versions")
          expect(logger).to receive(:warn).with("ALTER DATABASE main REFRESH COLLATION VERSION;")
          expect(logger).to receive(:warn).with(
            "-- This updates all collation versions in the database to match the current OS"
          )

          # Test conclusion
          expect(logger).to receive(:warn).with("\n3. Take GitLab out of maintenance mode")
          expect(logger).to receive(:warn).with("\nFor more information, see: https://docs.gitlab.com/administration/postgresql/upgrading_os/")

          result = checker.run

          expect(result['collation_mismatches']).to eq(mismatches)
          expect(result['corrupted_indexes']).to eq(corrupted_indexes)
        end
      end

      context 'with table size-based skipping' do
        let(:small_index) do
          {
            'table_name' => 'small_table',
            'index_name' => 'index_small_table',
            'affected_columns' => 'name',
            'is_unique' => 't',
            'table_size_bytes' => 100.megabytes,
            'index_size_bytes' => 10.megabytes
          }
        end

        let(:large_index) do
          {
            'table_name' => 'large_table',
            'index_name' => 'index_large_table',
            'affected_columns' => 'name',
            'is_unique' => 't',
            'table_size_bytes' => 2.gigabytes, # Exceeds default threshold (1GB)
            'index_size_bytes' => 200.megabytes
          }
        end

        let(:indexes_to_check) { [{ 'table_name' => 'small_table' }, { 'table_name' => 'large_table' }] }

        it 'skips tables that exceed the size threshold' do
          allow(checker).to receive_messages(
            check_collation_mismatches: [],
            transform_indexes_to_spot_check: indexes_to_check,
            fetch_index_info: [small_index, large_index],
            identify_corrupted_indexes: []
          )

          expect(logger).to receive(:info).with("Skipping duplicate checks for 1 indexes due to large table size")
          expect(logger).to receive(:info).with(/Skipping index_large_table on table large_table/)

          result = checker.run

          expect(result['skipped_indexes']).to contain_exactly(
            hash_including(
              'index_name' => 'index_large_table',
              'table_name' => 'large_table',
              'table_size_bytes' => 2.gigabytes,
              'index_size_bytes' => 200.megabytes,
              'table_size_threshold' => described_class::MAX_TABLE_SIZE_FOR_DUPLICATE_CHECK,
              'reason' => 'table_size_exceeds_threshold'
            )
          )
        end

        it 'respects custom table size threshold' do
          small_threshold = 50.megabytes
          checker_with_small_threshold = described_class.new(connection, database_name, logger, small_threshold)

          allow(checker_with_small_threshold).to receive_messages(
            check_collation_mismatches: [],
            transform_indexes_to_spot_check: indexes_to_check,
            fetch_index_info: [small_index, large_index],
            identify_corrupted_indexes: []
          )

          # Both tables should be skipped since small_threshold is 50MB
          expect(logger).to receive(:info).with("Skipping duplicate checks for 2 indexes due to large table size")

          result = checker_with_small_threshold.run

          expect(result['skipped_indexes'].size).to eq(2)
          expect(result['skipped_indexes']).to include(
            hash_including('index_name' => 'index_small_table'),
            hash_including('index_name' => 'index_large_table')
          )
        end
      end
    end

    # Real database test for the happy path
    context 'with real database connection' do
      let(:connection) { ActiveRecord::Base.connection }
      let(:database_name) { connection.current_database }
      let(:logger) { instance_double(Logger, info: nil, warn: nil, error: nil) }
      let(:checker) do
        described_class.new(connection, database_name, logger, described_class::MAX_TABLE_SIZE_FOR_DUPLICATE_CHECK)
      end

      let(:table_name) { '_test_c_collation_table' }
      let(:index_name) { '_test_c_collation_index' }
      let(:c_collation) { 'C' } # Use standard C collation which should be available

      # Find the real OID of the C collation for our test
      let!(:c_collation_info) do
        connection.select_all(
          "SELECT oid FROM pg_collation WHERE collname = '#{c_collation}' AND collprovider = 'c' LIMIT 1"
        ).first
      end

      let(:stub_spot_check_hash) do
        {
          database_name => {
            table_name => [index_name]
          }
        }
      end

      before do
        skip 'C collation not found in database' unless c_collation_info

        # Make sure any existing test tables are cleaned up
        connection.execute("DROP TABLE IF EXISTS #{table_name} CASCADE;")

        # Create test table with TWO columns using C collation
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name} (
            id serial PRIMARY KEY,
            test_col varchar(255) COLLATE "#{c_collation}" NULL,
            test_col2 varchar(255) COLLATE "#{c_collation}" NULL
          );
        SQL

        # Create a regular non-unique index
        connection.execute(<<~SQL)
          CREATE INDEX #{index_name} ON #{table_name} (test_col, test_col2);
        SQL
        connection.execute(<<~SQL)
          INSERT INTO #{table_name} (test_col, test_col2) VALUES ('value1', 'valueA');
          INSERT INTO #{table_name} (test_col, test_col2) VALUES ('value1', NULL);
          INSERT INTO #{table_name} (test_col, test_col2) VALUES (NULL, 'valueA');
        SQL

        stub_const("#{described_class}::INDEXES_TO_SPOT_CHECK", stub_spot_check_hash)
      end

      it 'detects collation mismatches' do
        allow(checker).to receive(:check_collation_mismatches) do
          # Create a modified query to simulate actual version being different
          modified_query = described_class::COLLATION_VERSION_MISMATCH_QUERY
            .gsub('collversion', "'123.456'")
            .gsub('pg_collation_actual_version(oid)', "'987.654.321'")

          connection.select_all(modified_query).to_a
        end

        result = checker.run

        collation_mismatches = result['collation_mismatches']
        expect(collation_mismatches).to be_kind_of(Array)
        expect(collation_mismatches.pluck('collation_name')).to include(c_collation)
        expect(result['corrupted_indexes']).to eq([])
      end

      context 'with duplicates corruption' do
        before do
          # Insert test data with duplicates
          connection.execute(<<~SQL)
          INSERT INTO #{table_name} (test_col, test_col2) VALUES ('value1', 'valueA');
          INSERT INTO #{table_name} (test_col, test_col2) VALUES ('value1', NULL); -- duplicate on col2 NULL
          INSERT INTO #{table_name} (test_col, test_col2) VALUES (NULL, 'valueA'); -- duplciate on col1 NULL
          SQL

          # For unique count check, we need to mock fetch_index_info as our index is not real unique
          allow(checker).to receive(:fetch_index_info).and_return([
            {
              'table_name' => table_name,
              'index_name' => index_name,
              'affected_columns' => 'test_col, test_col2',
              'is_unique' => 't',
              'table_size_bytes' => 10.megabytes,
              'index_size_bytes' => 1.megabyte
            }
          ])
        end

        it 'detects duplicate values in unique constraints, ignoring NULLs in unique constraints' do
          result = checker.run

          corrupted_indexes = result['corrupted_indexes']
          expect(corrupted_indexes).to be_kind_of(Array)
          expect(corrupted_indexes.size).to eq(1) # NULLs don't count as duplicates

          expect(corrupted_indexes[0]).to include(
            {
              'index_name' => index_name,
              'table_name' => table_name,
              'corruption_types' => ['duplicates'],
              'needs_deduplication' => true
            }
          )
        end
      end
    end
  end
end

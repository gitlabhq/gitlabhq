# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::CollationChecker, feature_category: :database do
  describe '.run' do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
    let(:database_name) { 'main' }
    let(:logger) { instance_double(Gitlab::AppLogger, info: nil, warn: nil, error: nil) }

    it 'instantiates the class and calls run' do
      instance = instance_double(described_class)

      expect(Gitlab::Database::EachDatabase).to receive(:each_connection)
        .with(only: database_name)
        .and_yield(connection, database_name)

      expect(described_class).to receive(:new)
        .with(connection, database_name, logger)
        .and_return(instance)
      expect(instance).to receive(:run)

      described_class.run(database_name: database_name, logger: logger)
    end
  end

  describe '#run' do
    # Mock-based tests for edge cases and error handling
    context 'with mocked database connection' do
      let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }
      let(:database_name) { 'main' }
      let(:logger) { instance_double(Gitlab::AppLogger, info: nil, warn: nil, error: nil) }
      let(:checker) { described_class.new(connection, database_name, logger) }

      context 'when no collation mismatches are found' do
        let(:empty_results) { instance_double(ActiveRecord::Result, to_a: []) }

        before do
          allow(connection).to receive(:select_all)
            .with(described_class::COLLATION_VERSION_MISMATCH_QUERY)
            .and_return(empty_results)
        end

        it 'logs a success message and returns no mismatches' do
          expect(logger).to receive(:info).with("Checking for PostgreSQL collation mismatches on main database...")
          expect(logger).to receive(:info).with("No collation mismatches detected on main.")

          result = checker.run

          expect(result).to eq({ mismatches_found: false, affected_indexes: [] })
        end
      end

      context 'when collation mismatches exist but no indexes are affected' do
        let(:mismatches) do
          instance_double(
            ActiveRecord::Result,
            to_a: [{ 'collation_name' => 'en_US.utf8', 'stored_version' => '1.2.3', 'actual_version' => '1.2.4' }]
          )
        end

        let(:empty_affected) { instance_double(ActiveRecord::Result, to_a: []) }

        before do
          allow(connection).to receive(:quote)
            .with('en_US.utf8')
            .and_return("'en_US.utf8'")

          allow(connection).to receive(:select_all)
            .with(described_class::COLLATION_VERSION_MISMATCH_QUERY)
            .and_return(mismatches)

          allow(connection).to receive(:select_all)
            .with(/SELECT DISTINCT.*FROM.*pg_collation.*WHERE.*collname IN \('en_US.utf8'\)/m)
            .and_return(empty_affected)
        end

        it 'logs warnings about mismatches but reports no affected indexes' do
          expect(logger).to receive(:info).with("Checking for PostgreSQL collation mismatches on main database...")
          expect(logger).to receive(:warn).with("⚠️ COLLATION MISMATCHES DETECTED on main database!")
          expect(logger).to receive(:warn).with("1 collation(s) have version mismatches:")
          expect(logger).to receive(:warn).with("  - en_US.utf8: stored=1.2.3, actual=1.2.4")
          expect(logger).to receive(:info).with("No indexes appear to be affected by the collation mismatches.")

          result = checker.run

          expect(result).to eq({ mismatches_found: true, affected_indexes: [] })
        end
      end

      context 'when collation mismatches exist and indexes are affected (mock version)' do
        let(:mismatches) do
          instance_double(
            ActiveRecord::Result,
            to_a: [{ 'collation_name' => 'en_US.utf8', 'stored_version' => '1.2.3', 'actual_version' => '1.2.4' }]
          )
        end

        let(:affected_indexes) do
          instance_double(
            ActiveRecord::Result,
            to_a: [
              {
                'table_name' => 'projects',
                'index_name' => 'index_projects_on_name',
                'affected_columns' => 'name',
                'index_type' => 'btree',
                'is_unique' => 't'
              },
              {
                'table_name' => 'users',
                'index_name' => 'index_users_on_username',
                'affected_columns' => 'username',
                'index_type' => 'btree',
                'is_unique' => 'f'
              }
            ]
          )
        end

        before do
          allow(connection).to receive(:select_all)
            .with(described_class::COLLATION_VERSION_MISMATCH_QUERY)
            .and_return(mismatches)

          allow(connection).to receive(:quote)
            .with('en_US.utf8')
            .and_return("'en_US.utf8'")

          allow(connection).to receive(:select_all)
            .with(/SELECT DISTINCT.*FROM.*pg_collation.*WHERE.*collname IN \('en_US.utf8'\)/m)
            .and_return(affected_indexes)
        end

        it 'logs warnings and provides remediation guidance' do
          # Test basic detection
          expect(logger).to receive(:info).with("Checking for PostgreSQL collation mismatches on main database...")
          expect(logger).to receive(:warn).with("⚠️ COLLATION MISMATCHES DETECTED on main database!")
          expect(logger).to receive(:warn).with("1 collation(s) have version mismatches:")
          expect(logger).to receive(:warn).with("  - en_US.utf8: stored=1.2.3, actual=1.2.4")

          # Test affected indexes are listed
          expect(logger).to receive(:warn).with("Affected indexes that need to be rebuilt:")
          expect(logger).to receive(:warn).with("  - index_projects_on_name (btree) on table projects")
          expect(logger).to receive(:warn).with("    • Affected columns: name")
          expect(logger).to receive(:warn).with("    • Type: UNIQUE")
          expect(logger).to receive(:warn).with("  - index_users_on_username (btree) on table users")
          expect(logger).to receive(:warn).with("    • Affected columns: username")
          expect(logger).to receive(:warn).with("    • Type: NON-UNIQUE")

          # Test remediation header
          expect(logger).to receive(:warn).with("\nREMEDIATION STEPS:")
          expect(logger).to receive(:warn).with("1. Put GitLab into maintenance mode")
          expect(logger).to receive(:warn).with("2. Run the following SQL commands:")

          # Test duplicate entry checks
          expect(logger).to receive(:warn).with("\n# Step 1: Check for duplicate entries in unique indexes")
          expect(logger).to receive(:warn).with(
            "-- Check for duplicates in projects (unique index: index_projects_on_name)"
          )
          expect(logger).to receive(:warn).with(
            /SELECT name, COUNT\(\*\), ARRAY_AGG\(id\) FROM projects GROUP BY name HAVING COUNT\(\*\) > 1 LIMIT 1;/
          )
          expect(logger).to receive(:warn).with(/\n# If duplicates exist/)

          # Test index rebuild commands
          expect(logger).to receive(:warn).with("\n# Step 2: Rebuild affected indexes")
          expect(logger).to receive(:warn).with("# Option A: Rebuild individual indexes with minimal downtime:")
          expect(logger).to receive(:warn).with("REINDEX INDEX index_projects_on_name CONCURRENTLY;")
          expect(logger).to receive(:warn).with("REINDEX INDEX index_users_on_username CONCURRENTLY;")
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

          expect(result).to include(mismatches_found: true)
          expect(result[:affected_indexes]).to eq(affected_indexes.to_a)
        end
      end

      context 'when there is an error checking for mismatches' do
        before do
          allow(connection).to receive(:select_all)
            .with(described_class::COLLATION_VERSION_MISMATCH_QUERY)
            .and_raise(ActiveRecord::StatementInvalid, 'test error')
        end

        it 'logs the error and returns no mismatches' do
          expect(logger).to receive(:info).with("Checking for PostgreSQL collation mismatches on main database...")
          expect(logger).to receive(:error).with("Error checking collation mismatches: test error")

          result = checker.run

          expect(result).to eq({ mismatches_found: false, affected_indexes: [] })
        end
      end

      context 'when there is an error finding affected indexes' do
        let(:mismatches) do
          instance_double(
            ActiveRecord::Result,
            to_a: [{ 'collation_name' => 'en_US.utf8', 'stored_version' => '1.2.3', 'actual_version' => '1.2.4' }]
          )
        end

        before do
          allow(connection).to receive(:select_all)
            .with(described_class::COLLATION_VERSION_MISMATCH_QUERY)
            .and_return(mismatches)

          allow(connection).to receive(:quote)
            .with('en_US.utf8')
            .and_return("'en_US.utf8'")

          allow(connection).to receive(:select_all)
            .with(/SELECT DISTINCT.*FROM.*pg_collation.*WHERE.*collname IN \('en_US.utf8'\)/m)
            .and_raise(ActiveRecord::StatementInvalid, 'test error')
        end

        it 'logs the error and returns only mismatches' do
          expect(logger).to receive(:info).with("Checking for PostgreSQL collation mismatches on main database...")
          expect(logger).to receive(:warn).with("⚠️ COLLATION MISMATCHES DETECTED on main database!")
          expect(logger).to receive(:warn).with("1 collation(s) have version mismatches:")
          expect(logger).to receive(:warn).with("  - en_US.utf8: stored=1.2.3, actual=1.2.4")
          expect(logger).to receive(:error).with("Error finding affected indexes: test error")

          result = checker.run

          expect(result).to include(mismatches_found: true)
          expect(result[:affected_indexes]).to eq([])
        end
      end
    end

    # Real database test for the happy path
    context 'with real database connection' do
      let(:connection) { ActiveRecord::Base.connection }
      let(:database_name) { connection.current_database }
      let(:logger) { instance_double(Logger, info: nil, warn: nil, error: nil) }
      let(:checker) { described_class.new(connection, database_name, logger) }

      let(:table_name) { '_test_c_collation_table' }
      let(:index_name) { '_test_c_collation_index' }
      let(:c_collation) { 'C' } # Use standard C collation which should be available

      # Find the real OID of the C collation for our test
      let!(:c_collation_info) do
        connection.select_all(
          "SELECT oid FROM pg_collation WHERE collname = '#{c_collation}' AND collprovider = 'c' LIMIT 1"
        ).first
      end

      let!(:c_collation_oid) { c_collation_info&.[]('oid') }

      before do
        skip 'C collation not found in database' unless c_collation_info

        # Create test table with a column using C collation
        connection.execute(<<~SQL)
          CREATE TABLE #{table_name} (
            id serial PRIMARY KEY,
            test_col varchar(255) COLLATE "#{c_collation}" NOT NULL
          );
        SQL

        # Create an index on the collated column
        connection.execute(<<~SQL)
          CREATE INDEX #{index_name} ON #{table_name} (test_col);
        SQL

        # Insert test data
        connection.execute(<<~SQL)
          INSERT INTO #{table_name} (test_col) VALUES ('value1');
        SQL
      end

      after do
        connection.execute("DROP TABLE IF EXISTS #{table_name} CASCADE;")
      end

      it 'detects C collation mismatch and finds affected index' do
        allow(checker).to receive(:mismatched_collations) do
          # Create a modified query to simulate actual version being different
          modified_query = described_class::COLLATION_VERSION_MISMATCH_QUERY
            .gsub('collversion', "'123.456'")
            .gsub('pg_collation_actual_version(oid)', "'987.654.321'")

          connection.select_all(modified_query).to_a
        end

        # Run the checker with our mocked version mismatch
        result = checker.run

        # Verify we found mismatches
        expect(result[:mismatches_found]).to be true

        # Verify we found affected indexes
        expect(result[:affected_indexes]).not_to be_empty

        # Verify we found our test table index
        test_indexes = result[:affected_indexes].select { |idx| idx['table_name'] == table_name }

        expect(test_indexes).not_to be_empty, "Expected to find test table index but found none"
        expect(test_indexes.first['index_name']).to eq(index_name), "Expected to find our specific test index"

        # Verify remediation SQL includes our test index
        rebuild_commands = []
        allow(logger).to receive(:warn) do |message|
          rebuild_commands << message if message.include?('REINDEX INDEX')
        end

        # Run again to capture remediation SQL
        checker.run

        # Verify rebuild command for our test index
        expect(rebuild_commands.any? { |cmd| cmd.include?(index_name) }).to be true
      end
    end
  end
end

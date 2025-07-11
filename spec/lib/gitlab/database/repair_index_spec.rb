# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::RepairIndex, feature_category: :database do
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
        .with(connection, database_name, described_class::INDEXES_TO_REPAIR, logger, false)
        .and_return(instance)
      expect(instance).to receive(:run)

      described_class.run(database_name: database_name, logger: logger)
    end
  end

  describe '#run' do
    let(:connection) { ActiveRecord::Base.connection }
    let(:database_name) { connection.current_database }
    let(:logger) { instance_double(Gitlab::AppLogger, info: nil, warn: nil, error: nil) }
    let(:dry_run) { false }

    let(:test_table) { '_test_repair_index_table' }
    let(:test_unique_index) { '_test_repair_index_unique_idx' }
    let(:test_ref_table) { '_test_repair_index_ref_table' }
    let(:test_entity_ref_table) { '_test_repair_index_entity_ref_table' }
    let(:test_array_ref_table) { '_test_repair_index_array_ref_table' }
    let(:test_regular_index) { '_test_repair_regular_idx' }

    let(:indexes_to_repair) do
      {
        test_table => {
          test_unique_index => {
            'columns' => %w[name email],
            'unique' => true,
            'references' => [
              {
                'table' => test_ref_table,
                'column' => 'user_id'
              },
              {
                'table' => test_entity_ref_table,
                'column' => 'user_id',
                'entity_column' => 'entity_id'
              },
              {
                'table' => test_array_ref_table,
                'column' => 'user_ids',
                'type' => 'array'
              }
            ]
          },
          test_regular_index => {
            'columns' => %w[name],
            'unique' => false
          }
        }
      }
    end

    let(:repairer) { described_class.new(connection, database_name, indexes_to_repair, logger, dry_run) }

    before do
      connection.execute(<<~SQL)
          CREATE TABLE #{test_table} (
            id serial PRIMARY KEY,
            name varchar(255) NOT NULL,
            email varchar(255) NOT NULL
          );
      SQL

      connection.execute(<<~SQL)
          CREATE TABLE #{test_ref_table} (
            id serial PRIMARY KEY,
            user_id integer NOT NULL,
            data varchar(255) NOT NULL
          );
      SQL

      connection.execute(<<~SQL)
          CREATE TABLE #{test_entity_ref_table} (
            id serial PRIMARY KEY,
            user_id integer NOT NULL,
            entity_id integer NOT NULL,
            data varchar(255) NOT NULL
          );
      SQL

      connection.execute(<<~SQL)
          CREATE TABLE #{test_array_ref_table} (
            id serial PRIMARY KEY,
            user_ids bigint[] NOT NULL,
            data varchar(255) NOT NULL
          );
      SQL

      # Replace the SQL constants for tests to not use CONCURRENTLY
      stub_const(
        "#{described_class}::REINDEX_SQL",
        "REINDEX INDEX %{index_name}"
      )
      stub_const(
        "#{described_class}::CREATE_INDEX_SQL",
        "CREATE%{unique_clause} INDEX %{index_name} ON %{table_name} (%{column_list})"
      )
    end

    after do
      connection.execute("DROP TABLE IF EXISTS #{test_array_ref_table} CASCADE")
      connection.execute("DROP TABLE IF EXISTS #{test_entity_ref_table} CASCADE")
      connection.execute("DROP TABLE IF EXISTS #{test_ref_table} CASCADE")
      connection.execute("DROP TABLE IF EXISTS #{test_table} CASCADE")
    end

    context 'when table does not exists' do
      let(:indexes_to_repair) { { '_non_existing_table_' => {} } }

      it 'logs that the table does not exist and skips processing' do
        expect(logger).to receive(:info).with(/Table '_non_existing_table_' does not exist/)

        repairer.run
      end
    end

    context 'when indexes do not exist' do
      it 'creates the indexes correctly' do
        repairer.run

        is_unique = connection.select_value(<<~SQL)
            SELECT indisunique
            FROM pg_index i
            JOIN pg_class c ON i.indexrelid = c.oid
            JOIN pg_class t ON i.indrelid = t.oid
            WHERE c.relname = '#{test_unique_index}'
            AND t.relname = '#{test_table}'
        SQL
        expect(is_unique).to be true

        regular_index_exists = connection.select_value(<<~SQL).present?
              SELECT 1
              FROM pg_indexes
              WHERE tablename = '#{test_table}'
              AND indexname = '#{test_regular_index}'
        SQL
        expect(regular_index_exists).to be true
      end
    end

    context 'when indexes already exist' do
      before do
        connection.execute(<<~SQL)
            CREATE INDEX #{test_regular_index} ON #{test_table} (name);
        SQL
        connection.execute(<<~SQL)
            CREATE UNIQUE INDEX #{test_unique_index} ON #{test_table} (name, email);
        SQL
      end

      it 'reindexes the existing indexes' do
        expect(logger).to receive(:info).with(/Index reindexed successfully/).twice

        repairer.run
      end
    end

    context 'with duplicate data and various reference types' do
      before do
        connection.execute(<<~SQL)
            CREATE INDEX #{test_regular_index} ON #{test_table} (name);
        SQL

        # Insert duplicate data
        connection.execute(<<~SQL)
            INSERT INTO #{test_table} (name, email) VALUES
            ('test_user', 'test@example.com'),   -- ID 1
            ('test_user', 'test@example.com'),   -- ID 2 (duplicate)
            ('other_user', 'other@example.com'); -- ID 3
        SQL

        # Create standard references (no entity column)
        connection.execute(<<~SQL)
            INSERT INTO #{test_ref_table} (user_id, data) VALUES
            (1, 'ref to good ID'),
            (2, 'ref to bad ID - will be updated');
        SQL

        # Create a unique index on reference table to check reference update does not violate uniqueness
        connection.execute(<<~SQL)
            CREATE INDEX unique_test_index_reference ON #{test_entity_ref_table} (user_id, entity_id);
        SQL
        # Create entity-based references
        connection.execute(<<~SQL)
            INSERT INTO #{test_entity_ref_table} (user_id, entity_id, data) VALUES
            (1, 100, 'entity ref to good ID'),
            (2, 100, 'entity ref to bad ID - will be deleted'),
            (2, 200, 'entity ref to bad ID - will be updated');
        SQL

        # Create array references
        connection.execute(<<~SQL)
            INSERT INTO #{test_array_ref_table} (user_ids, data) VALUES
            ('{1,3}', 'array without bad IDs'),
            ('{2,3}', 'array with bad ID');
        SQL
      end

      it 'handles all reference types correctly' do
        # before: 3 users, various references
        user_count_before = connection.select_value("SELECT COUNT(*) FROM #{test_table}")
        expect(user_count_before).to eq(3)

        # unique index doesn't exist yet
        index_exists_before = connection.select_value(<<~SQL).present?
            SELECT 1
            FROM pg_indexes
            WHERE tablename = '#{test_table}'
            AND indexname = '#{test_unique_index}'
        SQL
        expect(index_exists_before).to be false

        repairer.run

        # after: 2 users (duplicate removed)
        user_count_after = connection.select_value("SELECT COUNT(*) FROM #{test_table}")
        expect(user_count_after).to eq(2)

        # standard reference updated to good ID
        standard_ref = connection.select_value(
          "SELECT user_id FROM #{test_ref_table} WHERE data = 'ref to bad ID - will be updated'"
        )
        expect(standard_ref).to eq(1) # Updated from 2 to 1

        # entity-based reference: duplicate deleted
        entity_100_refs = connection.select_all("SELECT * FROM #{test_entity_ref_table} WHERE entity_id = 100").to_a
        expect(entity_100_refs.size).to eq(1)
        expect(entity_100_refs.first['user_id']).to eq(1) # Update from 2 to 1

        # entity-based reference: non-duplicate updated
        entity_200_ref = connection.select_value("SELECT user_id FROM #{test_entity_ref_table} WHERE entity_id = 200")
        expect(entity_200_ref).to eq(1) # Updated from 2 to 1

        # array reference updated
        array_after = connection.select_value(
          "SELECT user_ids FROM #{test_array_ref_table} WHERE data = 'array with bad ID'"
        )
        expect(array_after).to eq("{1,3}") # Update from {2,3} to {1,3}

        # unique index is created correctly
        is_unique = connection.select_value(<<~SQL)
            SELECT indisunique
            FROM pg_index i
            JOIN pg_class c ON i.indexrelid = c.oid
            JOIN pg_class t ON i.indrelid = t.oid
            WHERE c.relname = '#{test_unique_index}'
            AND t.relname = '#{test_table}'
        SQL
        expect(is_unique).to be true
      end

      context 'with dry run' do
        let(:dry_run) { true }

        it 'analyzes data but does not make changes' do
          expect(logger).to receive(:info).with(/Analysis only, no changes will be made/).at_least(:once)

          user_count_before = connection.select_value("SELECT COUNT(*) FROM #{test_table}")
          standard_ref_before = connection.select_value(
            "SELECT user_id FROM #{test_ref_table} WHERE data = 'ref to bad ID - will be updated'"
          )
          entity_refs_before = connection.select_all("SELECT * FROM #{test_entity_ref_table}").to_a
          array_ref_before = connection.select_value(
            "SELECT user_ids FROM #{test_array_ref_table} WHERE data = 'array with bad ID'"
          )

          repairer.run

          user_count_after = connection.select_value("SELECT COUNT(*) FROM #{test_table}")
          standard_ref_after = connection.select_value(
            "SELECT user_id FROM #{test_ref_table} WHERE data = 'ref to bad ID - will be updated'"
          )
          entity_refs_after = connection.select_all("SELECT * FROM #{test_entity_ref_table}").to_a
          array_ref_after = connection.select_value(
            "SELECT user_ids FROM #{test_array_ref_table} WHERE data = 'array with bad ID'"
          )

          expect(user_count_after).to eq(user_count_before)
          expect(standard_ref_after).to eq(standard_ref_before)
          expect(entity_refs_after).to match_array(entity_refs_before)
          expect(array_ref_after).to eq(array_ref_before)

          unique_index_exists = connection.select_value(<<~SQL).present?
              SELECT 1
              FROM pg_indexes
              WHERE tablename = '#{test_table}'
              AND indexname = '#{test_unique_index}'
          SQL
          expect(unique_index_exists).to be false
        end
      end
    end
  end
end

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
                'deduplication_column' => 'deduplication_id'
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
            name varchar(255) NULL,
            email varchar(255) NULL
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
            deduplication_id integer NOT NULL,
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
            ('test_user', NULL),                 -- ID 3, email NULL, should be preserved
            (NULL, 'other@example.com'),         -- ID 4, name NULL, should be preserved
            ('other_user', 'other@example.com'); -- ID 5
        SQL

        # Create standard references (no entity column)
        connection.execute(<<~SQL)
            INSERT INTO #{test_ref_table} (user_id, data) VALUES
            (1, 'ref to good ID'),
            (2, 'ref to bad ID - will be updated');
        SQL

        # Create a unique index on reference table to check reference update does not violate uniqueness
        connection.execute(<<~SQL)
            CREATE INDEX unique_test_index_reference ON #{test_entity_ref_table} (user_id, deduplication_id);
        SQL
        # Create entity-based references
        connection.execute(<<~SQL)
            INSERT INTO #{test_entity_ref_table} (user_id, deduplication_id, data) VALUES
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
        expect(user_count_before).to eq(5)

        # unique index doesn't exist yet
        index_exists_before = connection.select_value(<<~SQL).present?
            SELECT 1
            FROM pg_indexes
            WHERE tablename = '#{test_table}'
            AND indexname = '#{test_unique_index}'
        SQL
        expect(index_exists_before).to be false

        repairer.run

        # after: 4 users (only true duplicate ID 2 removed)
        # ID 3 with NULL value preserved
        user_count_after = connection.select_value("SELECT COUNT(*) FROM #{test_table}")
        expect(user_count_after).to eq(4)

        # Verify NULL values are preserved
        null_records = connection.select_value(
          "SELECT COUNT(*) FROM #{test_table} WHERE email IS NULL or name is NULL"
        )
        expect(null_records).to eq(2)

        # standard reference updated to good ID
        standard_ref = connection.select_value(
          "SELECT user_id FROM #{test_ref_table} WHERE data = 'ref to bad ID - will be updated'"
        )
        expect(standard_ref).to eq(1) # Updated from 2 to 1

        # entity-based reference: duplicate deleted
        entity_100_refs = connection.select_all(
          "SELECT * FROM #{test_entity_ref_table} WHERE deduplication_id = 100"
        ).to_a
        expect(entity_100_refs.size).to eq(1)
        expect(entity_100_refs.first['user_id']).to eq(1) # Update from 2 to 1

        # entity-based reference: non-duplicate updated
        entity_200_ref = connection.select_value(
          "SELECT user_id FROM #{test_entity_ref_table} WHERE deduplication_id = 200"
        )
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

      context 'with unique constraint conflicts in references' do
        let(:test_constraint_table) { '_test_constraint_table' }
        let(:test_constraint_index) { '_test_constraint_unique_idx' }
        let(:indexes_to_repair) do
          {
            test_table => {
              test_unique_index => {
                'columns' => %w[name email],
                'unique' => true,
                'references' => [
                  {
                    'table' => test_constraint_table,
                    'column' => 'user_id',
                    'deduplication_column' => 'version'
                  }
                ]
              }
            }
          }
        end

        before do
          # Create a table with a unique constraint
          connection.execute(<<~SQL)
            CREATE TABLE #{test_constraint_table} (
              id serial PRIMARY KEY,
              user_id integer NOT NULL,
              version varchar(255) NOT NULL,
              data varchar(255) NOT NULL,
              UNIQUE(user_id, version)
            );
          SQL
          connection.execute(<<~SQL)
            CREATE UNIQUE INDEX #{test_constraint_index} ON #{test_constraint_table} (user_id, version);
          SQL

          # Insert test data with potential conflicts
          connection.execute(<<~SQL)
            INSERT INTO #{test_constraint_table} (user_id, version, data) VALUES
            (1, '1.0.0', 'version 1.0.0 for good ID'),
            (2, '1.0.0', 'version 1.0.0 for bad ID - would cause conflict on update'),
            (2, '2.0.0', 'version 2.0.0 for bad ID - safe to update');
          SQL
        end

        after do
          connection.execute("DROP TABLE IF EXISTS #{test_constraint_table} CASCADE")
        end

        it 'handles unique constraint conflicts correctly' do
          records_before = connection.select_all("SELECT * FROM #{test_constraint_table}").to_a
          expect(records_before.size).to eq(3)

          repairer.run

          # After repair: only conflicting record should be deleted
          records_after = connection.select_all("SELECT * FROM #{test_constraint_table}").to_a
          expect(records_after.size).to eq(2)

          # Version 1.0.0 record should remain with user_id=1
          version_1 = connection.select_value(
            "SELECT user_id FROM #{test_constraint_table} WHERE version = '1.0.0'"
          )
          expect(version_1).to eq(1)

          # Version 2.0.0 record should be updated to user_id=1
          version_2 = connection.select_value(
            "SELECT user_id FROM #{test_constraint_table} WHERE version = '2.0.0'"
          )
          expect(version_2).to eq(1)

          # Verify unique index created on main test_table
          test_index_exists_before = connection.select_value(<<~SQL).present?
            SELECT 1
            FROM pg_indexes
            WHERE tablename = '#{test_table}'
            AND indexname = '#{test_unique_index}'
          SQL
          expect(test_index_exists_before).to be true
        end
      end

      context 'when references table does not exists' do
        let(:indexes_to_repair) do
          {
            test_table => {
              test_unique_index => {
                'columns' => %w[name email],
                'unique' => true,
                'references' => [
                  {
                    'table' => '_non_existing_reference_table_',
                    'column' => 'user_id'
                  }
                ]
              }
            }
          }
        end

        it 'logs that the table does not exist and skips processing' do
          expect(logger).to receive(:info).with(/Reference table '_non_existing_reference_table_' does not exist/)
          expect(repairer).not_to receive(:update_references)

          repairer.run
        end
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

    context 'with action update' do
      let(:test_update_table) { '_test_update_table' }
      let(:test_update_index) { '_test_update_index' }

      let(:indexes_to_repair) do
        {
          test_update_table => {
            test_update_index => {
              'columns' => %w[group_id name],
              'unique' => true,
              'action' => 'update',
              'max_length' => 72,
              'column_to_update' => 'name'
            }
          }
        }
      end

      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{test_update_table} (
            id serial PRIMARY KEY,
            group_id integer NOT NULL,
            name varchar(72) NOT NULL,
            url varchar(255) NOT NULL,
            CONSTRAINT check_name_length CHECK (char_length(name) <= 72)
          );
        SQL

        connection.execute(<<~SQL)
          INSERT INTO #{test_update_table} (id, group_id, name, url) VALUES
          (1, 1, 'destination', 'https://example.com/webhook-0'),
          (2, 1, 'destination', 'https://example.com/webhook-1'),
          (3, 1, 'destination', 'https://example.com/webhook-2');
        SQL

        connection.execute(<<~SQL)
          SELECT setval(pg_get_serial_sequence('#{test_update_table}', 'id'), 3, true);
        SQL
      end

      after do
        connection.execute("DROP TABLE IF EXISTS #{test_update_table} CASCADE")
      end

      it 'updates duplicates instead of merging them' do
        records_before = connection.select_value("SELECT COUNT(*) FROM #{test_update_table}")
        expect(records_before).to eq(3)

        repairer.run

        # All records should be preserved
        records_after = connection.select_value("SELECT COUNT(*) FROM #{test_update_table}")
        expect(records_after).to eq(3)

        # Check the names were updated with -dup- suffix
        names = connection.select_values("SELECT name FROM #{test_update_table} ORDER BY id")
        expect(names[0]).to eq('destination')
        expect(names[1]).to eq('destination-dup-2')
        expect(names[2]).to eq('destination-dup-3')

        # All names should be unique now
        expect(names.uniq.size).to eq(3)

        # Index should be created successfully
        index_exists = connection.select_value(<<~SQL).present?
          SELECT 1
          FROM pg_indexes
          WHERE tablename = '#{test_update_table}'
          AND indexname = '#{test_update_index}'
        SQL
        expect(index_exists).to be true
      end

      context 'with long names that need truncation' do
        before do
          connection.execute("DELETE FROM #{test_update_table}")

          long_name = 'Very_Long_Destination_Name_That_Will_Need_Truncation_Sixtyseven_Ch'

          connection.execute(<<~SQL)
            INSERT INTO #{test_update_table} (id, group_id, name, url) VALUES
            (10, 1, '#{long_name}', 'https://example.com/webhook-0'),
            (11, 1, '#{long_name}', 'https://example.com/webhook-1'),
            (12, 1, '#{long_name}', 'https://example.com/webhook-2');
          SQL

          connection.execute(<<~SQL)
            SELECT setval(pg_get_serial_sequence('#{test_update_table}', 'id'), 12, true);
          SQL
        end

        it 'truncates names to fit within 72 character limit' do
          repairer.run

          records_after = connection.select_value("SELECT COUNT(*) FROM #{test_update_table}")
          expect(records_after).to eq(3)

          names = connection.select_values("SELECT name FROM #{test_update_table} ORDER BY id")

          # First record keeps original name
          expect(names[0]).to eq('Very_Long_Destination_Name_That_Will_Need_Truncation_Sixtyseven_Ch')

          # Other records should be truncated to fit max_length (72)
          # LEFT(name, 72 - LENGTH('-dup-11')) || '-dup-11' = 64 + 8 = 72 chars
          expect(names[1]).to eq('Very_Long_Destination_Name_That_Will_Need_Truncation_Sixtyseven_C-dup-11')
          expect(names[1].length).to eq(72)

          expect(names[2]).to eq('Very_Long_Destination_Name_That_Will_Need_Truncation_Sixtyseven_C-dup-12')
          expect(names[2].length).to eq(72)

          names[1..2].each do |name|
            expect(name.length).to eq(72)
            expect(name).to end_with('-dup-11').or end_with('-dup-12')
          end

          # All names should be unique
          expect(names.uniq.size).to eq(3)

          # Index should be created successfully despite truncation
          index_exists = connection.select_value(<<~SQL).present?
            SELECT 1
            FROM pg_indexes
            WHERE tablename = '#{test_update_table}'
            AND indexname = '#{test_update_index}'
          SQL
          expect(index_exists).to be true
        end
      end

      context 'with name exactly at 72 character limit' do
        before do
          connection.execute("DELETE FROM #{test_update_table}")

          max_length_name = 'A' * 72
          connection.execute(<<~SQL)
            INSERT INTO #{test_update_table} (id, group_id, name, url) VALUES
            (20, 1, '#{max_length_name}', 'https://example.com/webhook-0'),
            (21, 1, '#{max_length_name}', 'https://example.com/webhook-1');
          SQL

          connection.execute(<<~SQL)
            SELECT setval(pg_get_serial_sequence('#{test_update_table}', 'id'), 21, true);
          SQL
        end

        it 'truncates the base name to make room for suffix' do
          repairer.run

          records_after = connection.select_value("SELECT COUNT(*) FROM #{test_update_table}")
          expect(records_after).to eq(2)

          names = connection.select_values("SELECT name FROM #{test_update_table} ORDER BY id")

          # First record keeps original 72-char name
          expect(names[0].length).to eq(72)
          expect(names[0]).to eq('A' * 72)

          # Second record truncated to fit max_length (72)
          # LEFT(name, 72 - LENGTH('-dup-21')) || '-dup-21' = 65 + 7 = 72 chars
          expect(names[1]).to eq("#{'A' * 65}-dup-21")
          expect(names[1].length).to eq(72)
        end
      end

      context 'with multiple duplicate groups' do
        before do
          connection.execute("DELETE FROM #{test_update_table}")
          connection.execute(<<~SQL)
            INSERT INTO #{test_update_table} (id, group_id, name, url) VALUES
            (30, 1, 'destination-a', 'https://example.com/a-0'),
            (31, 1, 'destination-a', 'https://example.com/a-1'),
            (40, 2, 'destination-b', 'https://example.com/b-0'),
            (41, 2, 'destination-b', 'https://example.com/b-1'),
            (42, 2, 'destination-b', 'https://example.com/b-2');
          SQL

          connection.execute(<<~SQL)
            SELECT setval(pg_get_serial_sequence('#{test_update_table}', 'id'), 42, true);
          SQL
        end

        it 'handles multiple duplicate groups correctly' do
          repairer.run

          records_after = connection.select_value("SELECT COUNT(*) FROM #{test_update_table}")
          expect(records_after).to eq(5)

          group1_names = connection.select_values(
            "SELECT name FROM #{test_update_table} WHERE group_id = 1 ORDER BY id"
          )
          expect(group1_names[0]).to eq('destination-a')
          expect(group1_names[1]).to eq('destination-a-dup-31')

          group2_names = connection.select_values(
            "SELECT name FROM #{test_update_table} WHERE group_id = 2 ORDER BY id"
          )
          expect(group2_names[0]).to eq('destination-b')
          expect(group2_names[1]).to eq('destination-b-dup-41')
          expect(group2_names[2]).to eq('destination-b-dup-42')

          expect(group1_names.uniq.size).to eq(2)
          expect(group2_names.uniq.size).to eq(3)
        end
      end

      context 'with dry run' do
        let(:dry_run) { true }

        it 'does not update duplicates' do
          names_before = connection.select_values("SELECT name FROM #{test_update_table} ORDER BY id")

          repairer.run

          names_after = connection.select_values("SELECT name FROM #{test_update_table} ORDER BY id")
          expect(names_after).to eq(names_before)

          index_exists = connection.select_value(<<~SQL).present?
            SELECT 1
            FROM pg_indexes
            WHERE tablename = '#{test_update_table}'
            AND indexname = '#{test_update_index}'
          SQL
          expect(index_exists).to be false
        end
      end
    end
  end

  describe 'index repair list integrity validation' do
    it 'ensures all indexes in INDEXES_TO_REPAIR exist in the database schema' do
      indexes_to_repair = described_class::INDEXES_TO_REPAIR.values.flat_map(&:keys)

      missing_indexes = []

      indexes_to_repair.each do |index_name|
        index_exists = ActiveRecord::Base.connection.select_value(
          ActiveRecord::Base.sanitize_sql_array(['SELECT 1 FROM pg_indexes WHERE indexname = ?', index_name])
        )

        missing_indexes << index_name unless index_exists.present?
      end

      expect(missing_indexes).to be_empty,
        <<~MSG
          The following indexes are listed in INDEXES_TO_REPAIR but don't exist in the database:
          #{missing_indexes.map { |idx| "  - #{idx}" }.join("\n")}

          Please remove them from the INDEXES_TO_REPAIR constant or ensure they exist in the schema.
        MSG
    end
  end
end

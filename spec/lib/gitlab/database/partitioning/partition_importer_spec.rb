# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::PartitionImporter, feature_category: :database do
  include Database::PartitioningHelpers
  include Database::MultipleDatabasesHelpers
  include Gitlab::Database::MigrationHelpers::LooseForeignKeyHelpers

  let(:connection) { ApplicationRecord.connection }

  subject(:importer) { described_class.new(connection: connection) }

  def execute(sql)
    connection.execute(sql)
  end

  before do
    connection.execute(<<~SQL)
      CREATE TABLE _test_import_partitioned
        (id serial NOT NULL, project_id bigint NOT NULL, PRIMARY KEY (id, project_id))
        PARTITION BY RANGE (project_id);

      CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_import_partitioned_1
      PARTITION OF _test_import_partitioned
      FOR VALUES FROM ('1') TO ('100');
    SQL
  end

  after do
    connection.execute('DROP TABLE IF EXISTS _test_import_partitioned CASCADE')
  end

  describe '#import' do
    let(:table_definitions) do
      [
        {
          table_name: '_test_import_partitioned',
          partition_type: 'integer',
          partitions: [
            { partition_name: '_test_import_partitioned_1', from: 1, to: 100 },
            { partition_name: '_test_import_partitioned_100', from: 100, to: 200 }
          ]
        }
      ]
    end

    it 'is idempotent when run twice' do
      importer.import(table_definitions)
      result = importer.import(table_definitions)

      expect(result[:created]).to eq(0)
      expect(result[:skipped]).to eq(2)
    end

    context 'with string keys (JSON-parsed input)' do
      let(:string_key_definitions) do
        [
          {
            'table_name' => '_test_import_partitioned',
            'partition_type' => 'integer',
            'partitions' => [
              { 'partition_name' => '_test_import_partitioned_100', 'from' => 100, 'to' => 200 }
            ]
          }
        ]
      end

      it 'handles string keys correctly' do
        result = importer.import(string_key_definitions)

        expect(result[:created]).to eq(1)
        expect_range_partition_of('_test_import_partitioned_100', '_test_import_partitioned', "'100'", "'200'")
      end
    end

    context 'with a non-existent table' do
      let(:nonexistent_definitions) do
        [
          {
            table_name: '_test_nonexistent_table',
            partitions: [{ partition_name: '_test_nonexistent_table_1', from: 1, to: 100 }]
          }
        ]
      end

      it 'skips the table gracefully' do
        result = importer.import(nonexistent_definitions)

        expect(result[:tables_processed]).to eq(0)
        expect(result[:created]).to eq(0)
      end
    end

    context 'when the partitioned table has a loose foreign key trigger' do
      let(:table_definitions) do
        [
          {
            table_name: '_test_import_partitioned',
            partition_type: 'integer',
            partitions: [
              { partition_name: '_test_import_partitioned_100', from: 100, to: 200 }
            ]
          }
        ]
      end

      before do
        track_record_deletions('_test_import_partitioned')
      end

      it 'attaches LFK trigger on the imported partition' do
        importer.import(table_definitions)

        partition_name = '_test_import_partitioned_100'
        trigger_name = record_deletion_trigger_name(partition_name)

        expect(
          trigger_exists?(partition_name, trigger_name, Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA)
        ).to be(true)
      end
    end

    context 'when the partitioned table has no loose foreign key trigger' do
      let(:table_definitions) do
        [
          {
            table_name: '_test_import_partitioned',
            partition_type: 'integer',
            partitions: [
              { partition_name: '_test_import_partitioned_100', from: 100, to: 200 }
            ]
          }
        ]
      end

      it 'imports partitions without adding triggers' do
        importer.import(table_definitions)

        partition_name = '_test_import_partitioned_100'
        trigger_name = record_deletion_trigger_name(partition_name)

        expect(
          trigger_exists?(partition_name, trigger_name, Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA)
        ).to be(false)
      end
    end

    context 'with an empty partition list' do
      let(:empty_definitions) do
        [{ table_name: '_test_import_partitioned', partition_type: 'integer', partitions: [] }]
      end

      it 'returns zero counts' do
        result = importer.import(empty_definitions)

        expect(result[:created]).to eq(0)
        expect(result[:skipped]).to eq(0)
        expect(result[:tables_processed]).to eq(1)
      end
    end

    context 'with an empty table definitions list' do
      it 'returns zero counts' do
        result = importer.import([])

        expect(result[:created]).to eq(0)
        expect(result[:skipped]).to eq(0)
        expect(result[:tables_processed]).to eq(0)
      end
    end

    context 'with dry_run: true' do
      it 'reports missing partitions without creating them' do
        result = importer.import(table_definitions, dry_run: true)

        expect(result[:created]).to eq(1)
        expect(result[:skipped]).to eq(1)
        expect(result[:tables_processed]).to eq(1)

        expect(connection.table_exists?('_test_import_partitioned_100')).to be(false)
      end

      it 'logs what would be created' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(message: 'Dry run: would create partition', partition_name: '_test_import_partitioned_100')
        )

        importer.import(table_definitions, dry_run: true)
      end
    end

    context 'with integer range partitions' do
      it 'creates missing partitions and skips existing ones' do
        result = importer.import(table_definitions)

        expect(result[:created]).to eq(1)
        expect(result[:skipped]).to eq(1)
        expect(result[:tables_processed]).to eq(1)

        expect_range_partition_of('_test_import_partitioned_100', '_test_import_partitioned', "'100'", "'200'")
      end

      context 'with invalid partition bounds' do
        let(:invalid_bounds_definitions) do
          [
            {
              table_name: '_test_import_partitioned',
              partition_type: 'integer',
              partitions: [
                { partition_name: '_test_import_partitioned_invalid', from: 0, to: 100 }
              ]
            }
          ]
        end

        it 'skips invalid partitions, logs warnings, and raises with error summary' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            hash_including(
              message: 'Skipping invalid partition bounds',
              table_name: '_test_import_partitioned',
              partition_name: '_test_import_partitioned_invalid'
            )
          )

          expect do
            importer.import(invalid_bounds_definitions)
          end.to raise_error(
            Gitlab::Database::Partitioning::PartitionImporter::ImportError,
            /table=_test_import_partitioned partition=_test_import_partitioned_invalid/
          )
        end
      end

      context 'when existing partitions have unparseable conditions' do
        let(:unparseable_definitions) do
          [
            {
              table_name: '_test_import_partitioned',
              partition_type: 'integer',
              partitions: [
                { partition_name: '_test_import_partitioned_100', from: 100, to: 200 }
              ]
            }
          ]
        end

        it 'treats unparseable existing partitions as non-existent' do
          allow(Gitlab::Database::Partitioning::IntRangePartition).to receive(:from_sql)
            .and_raise(ArgumentError)

          result = importer.import(unparseable_definitions)
          expect(result[:created]).to eq(1)
        end
      end
    end

    context 'with list partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_list_import_partitioned
          (id serial NOT NULL, partition_id bigint NOT NULL, PRIMARY KEY (id, partition_id))
          PARTITION BY LIST (partition_id);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_list_import_partitioned_1
          PARTITION OF _test_list_import_partitioned
          FOR VALUES IN ('1');
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_list_import_partitioned CASCADE')
      end

      let(:list_table_definitions) do
        [
          {
            table_name: '_test_list_import_partitioned',
            partition_type: 'bigint',
            partition_strategy: 'list',
            partitions: [
              { partition_name: '_test_list_import_partitioned_1', values: [1] },
              { partition_name: '_test_list_import_partitioned_2', values: [2] }
            ]
          }
        ]
      end

      it 'creates missing list partitions and skips existing ones', :aggregate_failures do
        result = importer.import(list_table_definitions)

        expect(result[:created]).to eq(1)
        expect(result[:skipped]).to eq(1)
        expect(result[:tables_processed]).to eq(1)

        expect(connection.table_exists?(
          "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_list_import_partitioned_2"
        )).to be(true)
      end

      it 'is idempotent for list partitions', :aggregate_failures do
        importer.import(list_table_definitions)
        result = importer.import(list_table_definitions)

        expect(result[:created]).to eq(0)
        expect(result[:skipped]).to eq(2)
      end

      context 'with string keys (JSON-parsed input)' do
        let(:string_key_list_definitions) do
          [
            {
              'table_name' => '_test_list_import_partitioned',
              'partition_type' => 'bigint',
              'partition_strategy' => 'list',
              'partitions' => [
                { 'partition_name' => '_test_list_import_partitioned_2', 'values' => [2] }
              ]
            }
          ]
        end

        it 'handles string keys correctly', :aggregate_failures do
          result = importer.import(string_key_list_definitions)

          expect(result[:created]).to eq(1)
          expect(connection.table_exists?(
            "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_list_import_partitioned_2"
          )).to be(true)
        end
      end

      context 'with multi-value list partition data' do
        let(:multi_value_definitions) do
          [
            {
              table_name: '_test_list_import_partitioned',
              partition_type: 'bigint',
              partition_strategy: 'list',
              partitions: [
                { partition_name: '_test_list_import_partitioned_1_2', values: [1, 2] }
              ]
            }
          ]
        end

        it 'raises ImportError — multi-value list partitions are not supported' do
          expect { importer.import(multi_value_definitions) }
            .to raise_error(
              Gitlab::Database::Partitioning::PartitionImporter::ImportError,
              /table=_test_list_import_partitioned/
            )
        end
      end
    end

    context 'with date range partitions' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE _test_date_import_partitioned
            (id serial NOT NULL, event_date date NOT NULL, PRIMARY KEY (id, event_date))
            PARTITION BY RANGE (event_date);

          CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_date_import_partitioned_202601
          PARTITION OF _test_date_import_partitioned
          FOR VALUES FROM ('2026-01-01') TO ('2026-02-01');
        SQL
      end

      after do
        connection.execute('DROP TABLE IF EXISTS _test_date_import_partitioned CASCADE')
      end

      let(:date_table_definitions) do
        [
          {
            table_name: '_test_date_import_partitioned',
            partition_type: 'date',
            partitions: [
              { partition_name: '_test_date_import_partitioned_202601', from: '2026-01-01', to: '2026-02-01' },
              { partition_name: '_test_date_import_partitioned_202602', from: '2026-02-01', to: '2026-03-01' }
            ]
          }
        ]
      end

      it 'creates missing date partitions and skips existing ones' do
        result = importer.import(date_table_definitions)

        expect(result[:created]).to eq(1)
        expect(result[:skipped]).to eq(1)
        expect(result[:tables_processed]).to eq(1)

        expect_range_partition_of(
          '_test_date_import_partitioned_202602',
          '_test_date_import_partitioned',
          "'2026-02-01'",
          "'2026-03-01'"
        )
      end

      context 'with invalid date values' do
        let(:invalid_date_definitions) do
          [
            {
              table_name: '_test_date_import_partitioned',
              partition_type: 'date',
              partitions: [
                { partition_name: '_test_date_import_partitioned_bad', from: 'not-a-date', to: '2026-03-01' }
              ]
            }
          ]
        end

        it 'skips the invalid partition and raises with error summary' do
          expect(Gitlab::AppLogger).to receive(:warn).with(
            hash_including(
              message: 'Skipping invalid partition definition',
              table_name: '_test_date_import_partitioned',
              partition_name: '_test_date_import_partitioned_bad'
            )
          )

          expect do
            importer.import(invalid_date_definitions)
          end.to raise_error(
            Gitlab::Database::Partitioning::PartitionImporter::ImportError,
            /table=_test_date_import_partitioned partition=_test_date_import_partitioned_bad/
          )
        end
      end

      context 'when an existing partition covers the source partition range' do
        before do
          connection.execute(<<~SQL)
            CREATE TABLE #{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}._test_date_import_partitioned_000000
            PARTITION OF _test_date_import_partitioned
            FOR VALUES FROM (MINVALUE) TO ('2026-01-01');
          SQL
        end

        let(:covered_definitions) do
          [
            {
              table_name: '_test_date_import_partitioned',
              partition_type: 'date',
              partitions: [
                { partition_name: '_test_date_import_partitioned_202001', from: '2020-01-01', to: '2020-02-01' }
              ]
            }
          ]
        end

        it 'skips the partition without error' do
          result = importer.import(covered_definitions)

          expect(result[:created]).to eq(0)
          expect(result[:skipped]).to eq(1)
          expect(result[:tables_processed]).to eq(1)
        end
      end

      context 'when existing date partitions have unparseable conditions' do
        let(:definitions) do
          [
            {
              table_name: '_test_date_import_partitioned',
              partition_type: 'date',
              partitions: [
                { partition_name: '_test_date_import_partitioned_202602', from: '2026-02-01', to: '2026-03-01' }
              ]
            }
          ]
        end

        it 'treats unparseable existing partitions as non-existent' do
          allow(Gitlab::Database::Partitioning::TimePartition).to receive(:from_sql)
            .and_raise(ArgumentError)

          result = importer.import(definitions)
          expect(result[:created]).to eq(1)
        end
      end
    end
  end

  # Happy-path UTC session guard (UNTAGGED).
  #
  # Under the default (UTC) session the guard must be a no-op and #import must
  # behave exactly as before, including in dry-run. These run in the normal
  # `rspec unit` jobs against CI's primary `postgres`, which may report a
  # UTC-equivalent value such as `Etc/UTC` or `GMT`; the guard normalizes those
  # (see EnsureUtcSession::UTC_TIMEZONES) rather than comparing strictly.
  describe '#import (UTC session guard)' do
    it 'does not raise under the default (UTC) session' do
      expect { importer.import([]) }.not_to raise_error
    end

    it 'does not raise under UTC even in dry-run' do
      expect { importer.import([], dry_run: true) }.not_to raise_error
    end
  end

  # Guard proof (TAGGED :partition_tz), including dry-run.
  #
  # Under a genuinely non-UTC session the guard must raise before doing any
  # work -- and the dry-run case must ALSO raise, because the guard runs at the
  # top of #import before the dry-run branch. No SQL stubbing; the subject is
  # constructed with a real side connection (the `postgres-tz` instance) whose
  # SESSION TimeZone is forced non-UTC in the `before` hook.
  #
  # This test asserts only the OUTCOME (a raise under a non-UTC state). It puts
  # the connection into a non-UTC state via a session `SET timezone`, which is a
  # reliable lever regardless of whether the guard inspects the session zone or
  # the database's configured default. The assertion matches on a message
  # substring rather than an exact error class.
  describe '#import (non-UTC session guard)', :partition_tz do
    before do
      skip_unless_non_utc_database_available

      tz_connection.execute("SET timezone TO 'America/Los_Angeles'")
    end

    after do
      tz_connection.execute("SET timezone TO 'UTC'")
    end

    subject(:importer) { described_class.new(connection: tz_connection) }

    it 'raises on a real import under non-UTC' do
      expect { importer.import([]) }.to raise_error(/TimeZone.*UTC/i)
    end

    it 'raises on a dry-run import under non-UTC (guard runs before the dry-run branch)' do
      expect { importer.import([], dry_run: true) }.to raise_error(/TimeZone.*UTC/i)
    end
  end
end

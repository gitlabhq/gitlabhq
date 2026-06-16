# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Partitioning::PartitionImporter, feature_category: :database do
  include Database::PartitioningHelpers
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
end

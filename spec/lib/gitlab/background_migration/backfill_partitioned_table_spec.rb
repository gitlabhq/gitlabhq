# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillPartitionedTable, feature_category: :database do
  subject(:backfill_job) do
    described_class.new(
      start_id: 1,
      end_id: 3,
      batch_table: source_table,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      job_arguments: [destination_table],
      connection: connection
    )
  end

  let(:connection) { ApplicationRecord.connection }
  let(:source_table) { '_test_source_table' }
  let(:destination_table) { "#{source_table}_partitioned" }
  let(:source_model) { Class.new(ApplicationRecord) }
  let(:destination_model) { Class.new(ApplicationRecord) }

  describe '#perform' do
    context 'without the destination table' do
      let(:expected_error_message) do
        "exiting backfill migration because partitioned table '#{destination_table}' does not exist. " \
          "This could be due to rollback of the migration which created the partitioned table."
      end

      it 'raises an exception' do
        expect { backfill_job.perform }.to raise_error(expected_error_message)
      end
    end

    context 'with destination table being not partitioned' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{destination_table} (
            id serial NOT NULL,
            col1 int NOT NULL,
            col2 text NOT NULL,
            created_at timestamptz NOT NULL,
            PRIMARY KEY (id, created_at)
          )
        SQL
      end

      after do
        connection.drop_table destination_table
      end

      let(:expected_error_message) do
        "exiting backfill migration because the given destination table is not partitioned."
      end

      it 'raises an exception' do
        expect { backfill_job.perform }.to raise_error(expected_error_message)
      end
    end

    context 'when the destination table exists' do
      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{source_table} (
            id serial NOT NULL PRIMARY KEY,
            col1 int NOT NULL,
            col2 text NOT NULL,
            created_at timestamptz NOT NULL
          )
        SQL

        connection.execute(<<~SQL)
          CREATE TABLE #{destination_table} (
            id serial NOT NULL,
            col1 int NOT NULL,
            col2 text NOT NULL,
            created_at timestamptz NOT NULL,
            PRIMARY KEY (id, created_at)
          ) PARTITION BY RANGE (created_at)
        SQL

        connection.execute(<<~SQL)
          CREATE TABLE #{destination_table}_202001 PARTITION OF #{destination_table}
          FOR VALUES FROM ('2020-01-01') TO ('2020-02-01')
        SQL

        connection.execute(<<~SQL)
          CREATE TABLE #{destination_table}_202002 PARTITION OF #{destination_table}
          FOR VALUES FROM ('2020-02-01') TO ('2020-03-01')
        SQL

        source_model.table_name = source_table
        destination_model.table_name = destination_table
      end

      after do
        connection.drop_table source_table
        connection.drop_table destination_table
      end

      let(:timestamp) { Time.utc(2020, 1, 2).round }
      let!(:source1) { create_source_record(timestamp) }
      let!(:source2) { create_source_record(timestamp + 1.day) }
      let!(:source3) { create_source_record(timestamp + 1.month) }

      it 'copies data into the destination table idempotently' do
        expect(destination_model.count).to eq(0)

        backfill_job.perform

        expect(destination_model.count).to eq(3)

        source_model.find_each do |source_record|
          destination_record = destination_model.find_by_id(source_record.id)

          expect(destination_record.attributes).to eq(source_record.attributes)
        end

        backfill_job.perform

        expect(destination_model.count).to eq(3)
      end

      it 'breaks the assigned batch into smaller sub batches' do
        expect_next_instance_of(Gitlab::Database::PartitioningMigrationHelpers::BulkCopy) do |bulk_copy|
          expect(bulk_copy).to receive(:copy_relation) do |from_record, to_record|
            expect(from_record.id).to eq(source1.id)
            expect(to_record.id).to eq(source2.id)
          end

          expect(bulk_copy).to receive(:copy_relation) do |from_record, to_record|
            expect(from_record.id).to eq(source3.id)
            expect(to_record).to be_nil
          end
        end

        backfill_job.perform
      end
    end
  end

  def create_source_record(timestamp)
    source_model.create!(col1: 123, col2: 'original value', created_at: timestamp)
  end
end

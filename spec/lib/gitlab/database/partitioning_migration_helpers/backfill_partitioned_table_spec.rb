# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PartitioningMigrationHelpers::BackfillPartitionedTable, '#perform' do
  subject(:backfill_job) { described_class.new(connection: connection) }

  let(:connection) { ActiveRecord::Base.connection }
  let(:source_table) { '_test_partitioning_backfills' }
  let(:destination_table) { "#{source_table}_part" }
  let(:unique_key) { 'id' }

  before do
    allow(backfill_job).to receive(:transaction_open?).and_return(false)
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

      stub_const("#{described_class}::SUB_BATCH_SIZE", 2)
      stub_const("#{described_class}::PAUSE_SECONDS", pause_seconds)

      allow(backfill_job).to receive(:sleep)
    end

    after do
      connection.drop_table source_table
      connection.drop_table destination_table
    end

    let(:source_model) { Class.new(ActiveRecord::Base) }
    let(:destination_model) { Class.new(ActiveRecord::Base) }
    let(:timestamp) { Time.utc(2020, 1, 2).round }
    let(:pause_seconds) { 1 }

    let!(:source1) { create_source_record(timestamp) }
    let!(:source2) { create_source_record(timestamp + 1.day) }
    let!(:source3) { create_source_record(timestamp + 1.month) }

    it 'copies data into the destination table idempotently' do
      expect(destination_model.count).to eq(0)

      backfill_job.perform(source1.id, source3.id, source_table, destination_table, unique_key)

      expect(destination_model.count).to eq(3)

      source_model.find_each do |source_record|
        destination_record = destination_model.find_by_id(source_record.id)

        expect(destination_record.attributes).to eq(source_record.attributes)
      end

      backfill_job.perform(source1.id, source3.id, source_table, destination_table, unique_key)

      expect(destination_model.count).to eq(3)
    end

    it 'breaks the assigned batch into smaller batches' do
      expect_next_instance_of(Gitlab::Database::PartitioningMigrationHelpers::BulkCopy) do |bulk_copy|
        expect(bulk_copy).to receive(:copy_between).with(source1.id, source2.id)
        expect(bulk_copy).to receive(:copy_between).with(source3.id, source3.id)
      end

      backfill_job.perform(source1.id, source3.id, source_table, destination_table, unique_key)
    end

    it 'pauses after copying each sub-batch' do
      expect(backfill_job).to receive(:sleep).with(pause_seconds).twice

      backfill_job.perform(source1.id, source3.id, source_table, destination_table, unique_key)
    end

    it 'marks each job record as succeeded after processing' do
      create(:background_migration_job,
        class_name: "::#{described_class.name}",
        arguments: [source1.id, source3.id, source_table, destination_table, unique_key])

      expect(::Gitlab::Database::BackgroundMigrationJob).to receive(:mark_all_as_succeeded).and_call_original

      expect do
        backfill_job.perform(source1.id, source3.id, source_table, destination_table, unique_key)
      end.to change { ::Gitlab::Database::BackgroundMigrationJob.succeeded.count }.from(0).to(1)
    end

    it 'returns the number of job records marked as succeeded' do
      create(:background_migration_job,
        class_name: "::#{described_class.name}",
        arguments: [source1.id, source3.id, source_table, destination_table, unique_key])

      jobs_updated = backfill_job.perform(source1.id, source3.id, source_table, destination_table, unique_key)

      expect(jobs_updated).to eq(1)
    end

    context 'when the job is run within an explicit transaction block' do
      subject(:backfill_job) { described_class.new(connection: mock_connection) }

      let(:mock_connection) { double('connection') }

      it 'raises an error before copying data' do
        expect(backfill_job).to receive(:transaction_open?).and_call_original

        expect(mock_connection).to receive(:transaction_open?).and_return(true)
        expect(mock_connection).not_to receive(:execute)

        expect do
          backfill_job.perform(1, 100, source_table, destination_table, unique_key)
        end.to raise_error(/Aborting job to backfill partitioned #{source_table}/)

        expect(destination_model.count).to eq(0)
      end
    end
  end

  context 'when the destination table does not exist' do
    subject(:backfill_job) { described_class.new(connection: mock_connection) }

    let(:mock_connection) { double('connection') }
    let(:mock_logger) { double('logger') }

    before do
      allow(backfill_job).to receive(:logger).and_return(mock_logger)
      allow(mock_logger).to receive(:warn)
    end

    it 'exits without attempting to copy data' do
      expect(mock_connection).to receive(:table_exists?).with(destination_table).and_return(false)
      expect(mock_connection).not_to receive(:execute)

      subject.perform(1, 100, source_table, destination_table, unique_key)
    end

    it 'logs a warning message that the job was skipped' do
      expect(mock_connection).to receive(:table_exists?).with(destination_table).and_return(false)
      expect(mock_logger).to receive(:warn).with(/'#{destination_table}' does not exist/)

      subject.perform(1, 100, source_table, destination_table, unique_key)
    end
  end

  def create_source_record(timestamp)
    source_model.create!(col1: 123, col2: 'original value', created_at: timestamp)
  end
end

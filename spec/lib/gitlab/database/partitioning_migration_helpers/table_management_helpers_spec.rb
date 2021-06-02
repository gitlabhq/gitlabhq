# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers do
  include Database::PartitioningHelpers
  include Database::TriggerHelpers
  include Database::TableSchemaHelpers

  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let_it_be(:connection) { ActiveRecord::Base.connection }

  let(:source_table) { :_test_original_table }
  let(:partitioned_table) { '_test_migration_partitioned_table' }
  let(:function_name) { '_test_migration_function_name' }
  let(:trigger_name) { '_test_migration_trigger_name' }
  let(:partition_column) { 'created_at' }
  let(:min_date) { Date.new(2019, 12) }
  let(:max_date) { Date.new(2020, 3) }
  let(:source_model) { Class.new(ActiveRecord::Base) }

  before do
    allow(migration).to receive(:puts)

    migration.create_table source_table do |t|
      t.string :name, null: false
      t.integer :age, null: false
      t.datetime partition_column
      t.datetime :updated_at
    end

    source_model.table_name = source_table

    allow(migration).to receive(:transaction_open?).and_return(false)
    allow(migration).to receive(:make_partitioned_table_name).and_return(partitioned_table)
    allow(migration).to receive(:make_sync_function_name).and_return(function_name)
    allow(migration).to receive(:make_sync_trigger_name).and_return(trigger_name)
    allow(migration).to receive(:assert_table_is_allowed)
  end

  describe '#partition_table_by_date' do
    let(:partition_column) { 'created_at' }
    let(:old_primary_key) { 'id' }
    let(:new_primary_key) { [old_primary_key, partition_column] }

    before do
      allow(migration).to receive(:queue_background_migration_jobs_by_range_at_intervals)
    end

    context 'when the table is not allowed' do
      let(:source_table) { :this_table_is_not_allowed }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

        expect do
          migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/#{source_table} is not allowed for use/)
      end
    end

    context 'when run inside a transaction block' do
      it 'raises an error' do
        expect(migration).to receive(:transaction_open?).and_return(true)

        expect do
          migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/can not be run inside a transaction/)
      end
    end

    context 'when the the max_date is less than the min_date' do
      let(:max_date) { Time.utc(2019, 6) }

      it 'raises an error' do
        expect do
          migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/max_date #{max_date} must be greater than min_date #{min_date}/)
      end
    end

    context 'when the max_date is equal to the min_date' do
      let(:max_date) { min_date }

      it 'raises an error' do
        expect do
          migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/max_date #{max_date} must be greater than min_date #{min_date}/)
      end
    end

    context 'when the given table does not have a primary key' do
      it 'raises an error' do
        migration.execute(<<~SQL)
          ALTER TABLE #{source_table}
          DROP CONSTRAINT #{source_table}_pkey
        SQL

        expect do
          migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/primary key not defined for #{source_table}/)
      end
    end

    context 'when an invalid partition column is given' do
      let(:invalid_column) { :_this_is_not_real }

      it 'raises an error' do
        expect do
          migration.partition_table_by_date source_table, invalid_column, min_date: min_date, max_date: max_date
        end.to raise_error(/partition column #{invalid_column} does not exist/)
      end
    end

    describe 'constructing the partitioned table' do
      it 'creates a table partitioned by the proper column' do
        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        expect(connection.table_exists?(partitioned_table)).to be(true)
        expect(connection.primary_key(partitioned_table)).to eq(new_primary_key)

        expect_table_partitioned_by(partitioned_table, [partition_column])
      end

      it 'changes the primary key datatype to bigint' do
        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

        expect(pk_column.sql_type).to eq('bigint')
      end

      context 'with a non-integer primary key datatype' do
        before do
          connection.create_table non_int_table, id: false do |t|
            t.string :identifier, primary_key: true
            t.timestamp :created_at
          end
        end

        let(:non_int_table) { :another_example }
        let(:old_primary_key) { 'identifier' }

        it 'does not change the primary key datatype' do
          migration.partition_table_by_date non_int_table, partition_column, min_date: min_date, max_date: max_date

          original_pk_column = connection.columns(non_int_table).find { |c| c.name == old_primary_key }
          pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

          expect(pk_column).not_to be_nil
          expect(pk_column).to eq(original_pk_column)
        end
      end

      it 'removes the default from the primary key column' do
        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

        expect(pk_column.default_function).to be_nil
      end

      it 'creates the partitioned table with the same non-key columns' do
        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        copied_columns = filter_columns_by_name(connection.columns(partitioned_table), new_primary_key)
        original_columns = filter_columns_by_name(connection.columns(source_table), new_primary_key)

        expect(copied_columns).to match_array(original_columns)
      end

      it 'creates a partition spanning over each month in the range given' do
        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        expect_range_partitions_for(partitioned_table, {
          '000000' => ['MINVALUE', "'2019-12-01 00:00:00'"],
          '201912' => ["'2019-12-01 00:00:00'", "'2020-01-01 00:00:00'"],
          '202001' => ["'2020-01-01 00:00:00'", "'2020-02-01 00:00:00'"],
          '202002' => ["'2020-02-01 00:00:00'", "'2020-03-01 00:00:00'"],
          '202003' => ["'2020-03-01 00:00:00'", "'2020-04-01 00:00:00'"]
        })
      end

      context 'when min_date is not given' do
        context 'with records present already' do
          before do
            source_model.create!(name: 'Test', age: 10, created_at: Date.parse('2019-11-05'))
          end

          it 'creates a partition spanning over each month from the first record' do
            migration.partition_table_by_date source_table, partition_column, max_date: max_date

            expect_range_partitions_for(partitioned_table, {
              '000000' => ['MINVALUE', "'2019-11-01 00:00:00'"],
              '201911' => ["'2019-11-01 00:00:00'", "'2019-12-01 00:00:00'"],
              '201912' => ["'2019-12-01 00:00:00'", "'2020-01-01 00:00:00'"],
              '202001' => ["'2020-01-01 00:00:00'", "'2020-02-01 00:00:00'"],
              '202002' => ["'2020-02-01 00:00:00'", "'2020-03-01 00:00:00'"],
              '202003' => ["'2020-03-01 00:00:00'", "'2020-04-01 00:00:00'"]
            })
          end
        end

        context 'without data' do
          it 'creates the catchall partition plus two actual partition' do
            migration.partition_table_by_date source_table, partition_column, max_date: max_date

            expect_range_partitions_for(partitioned_table, {
              '000000' => ['MINVALUE', "'2020-02-01 00:00:00'"],
              '202002' => ["'2020-02-01 00:00:00'", "'2020-03-01 00:00:00'"],
              '202003' => ["'2020-03-01 00:00:00'", "'2020-04-01 00:00:00'"]
            })
          end
        end
      end

      context 'when max_date is not given' do
        it 'creates partitions including the next month from today' do
          today = Date.new(2020, 5, 8)

          travel_to(today) do
            migration.partition_table_by_date source_table, partition_column, min_date: min_date

            expect_range_partitions_for(partitioned_table, {
              '000000' => ['MINVALUE', "'2019-12-01 00:00:00'"],
              '201912' => ["'2019-12-01 00:00:00'", "'2020-01-01 00:00:00'"],
              '202001' => ["'2020-01-01 00:00:00'", "'2020-02-01 00:00:00'"],
              '202002' => ["'2020-02-01 00:00:00'", "'2020-03-01 00:00:00'"],
              '202003' => ["'2020-03-01 00:00:00'", "'2020-04-01 00:00:00'"],
              '202004' => ["'2020-04-01 00:00:00'", "'2020-05-01 00:00:00'"],
              '202005' => ["'2020-05-01 00:00:00'", "'2020-06-01 00:00:00'"],
              '202006' => ["'2020-06-01 00:00:00'", "'2020-07-01 00:00:00'"]
            })
          end
        end
      end

      context 'without min_date, max_date' do
        it 'creates partitions for the current and next month' do
          current_date = Date.new(2020, 05, 22)
          travel_to(current_date.to_time) do
            migration.partition_table_by_date source_table, partition_column

            expect_range_partitions_for(partitioned_table, {
              '000000' => ['MINVALUE', "'2020-05-01 00:00:00'"],
              '202005' => ["'2020-05-01 00:00:00'", "'2020-06-01 00:00:00'"],
              '202006' => ["'2020-06-01 00:00:00'", "'2020-07-01 00:00:00'"]
            })
          end
        end
      end
    end

    describe 'keeping data in sync with the partitioned table' do
      let(:partitioned_model) { Class.new(ActiveRecord::Base) }
      let(:timestamp) { Time.utc(2019, 12, 1, 12).round }

      before do
        partitioned_model.primary_key = :id
        partitioned_model.table_name = partitioned_table
      end

      it 'creates a trigger function on the original table' do
        expect_function_not_to_exist(function_name)
        expect_trigger_not_to_exist(source_table, trigger_name)

        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        expect_function_to_exist(function_name)
        expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])
      end

      it 'syncs inserts to the partitioned tables' do
        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        expect(partitioned_model.count).to eq(0)

        first_record = source_model.create!(name: 'Bob', age: 20, created_at: timestamp, updated_at: timestamp)
        second_record = source_model.create!(name: 'Alice', age: 30, created_at: timestamp, updated_at: timestamp)

        expect(partitioned_model.count).to eq(2)
        expect(partitioned_model.find(first_record.id).attributes).to eq(first_record.attributes)
        expect(partitioned_model.find(second_record.id).attributes).to eq(second_record.attributes)
      end

      it 'syncs updates to the partitioned tables' do
        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        first_record = source_model.create!(name: 'Bob', age: 20, created_at: timestamp, updated_at: timestamp)
        second_record = source_model.create!(name: 'Alice', age: 30, created_at: timestamp, updated_at: timestamp)

        expect(partitioned_model.count).to eq(2)

        first_copy = partitioned_model.find(first_record.id)
        second_copy = partitioned_model.find(second_record.id)

        expect(first_copy.attributes).to eq(first_record.attributes)
        expect(second_copy.attributes).to eq(second_record.attributes)

        first_record.update!(age: 21, updated_at: timestamp + 1.hour)

        expect(partitioned_model.count).to eq(2)
        expect(first_copy.reload.attributes).to eq(first_record.attributes)
        expect(second_copy.reload.attributes).to eq(second_record.attributes)
      end

      it 'syncs deletes to the partitioned tables' do
        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        first_record = source_model.create!(name: 'Bob', age: 20, created_at: timestamp, updated_at: timestamp)
        second_record = source_model.create!(name: 'Alice', age: 30, created_at: timestamp, updated_at: timestamp)

        expect(partitioned_model.count).to eq(2)

        first_record.destroy!

        expect(partitioned_model.count).to eq(1)
        expect(partitioned_model.find_by_id(first_record.id)).to be_nil
        expect(partitioned_model.find(second_record.id).attributes).to eq(second_record.attributes)
      end
    end
  end

  describe '#drop_partitioned_table_for' do
    let(:expected_tables) do
      %w[000000 201912 202001 202002].map { |suffix| "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partitioned_table}_#{suffix}" }.unshift(partitioned_table)
    end

    let(:migration_class) { 'Gitlab::Database::PartitioningMigrationHelpers::BackfillPartitionedTable' }

    context 'when the table is not allowed' do
      let(:source_table) { :this_table_is_not_allowed }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

        expect do
          migration.drop_partitioned_table_for source_table
        end.to raise_error(/#{source_table} is not allowed for use/)
      end
    end

    it 'drops the trigger syncing to the partitioned table' do
      migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

      expect_function_to_exist(function_name)
      expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])

      migration.drop_partitioned_table_for source_table

      expect_function_not_to_exist(function_name)
      expect_trigger_not_to_exist(source_table, trigger_name)
    end

    it 'drops the partitioned copy and all partitions' do
      migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

      expected_tables.each do |table|
        expect(connection.table_exists?(table)).to be(true)
      end

      migration.drop_partitioned_table_for source_table

      expected_tables.each do |table|
        expect(connection.table_exists?(table)).to be(false)
      end
    end
  end

  describe '#enqueue_partitioning_data_migration' do
    context 'when the table is not allowed' do
      let(:source_table) { :this_table_is_not_allowed }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

        expect do
          migration.enqueue_partitioning_data_migration source_table
        end.to raise_error(/#{source_table} is not allowed for use/)
      end
    end

    context 'when run inside a transaction block' do
      it 'raises an error' do
        expect(migration).to receive(:transaction_open?).and_return(true)

        expect do
          migration.enqueue_partitioning_data_migration source_table
        end.to raise_error(/can not be run inside a transaction/)
      end
    end

    context 'when records exist in the source table' do
      let(:migration_class) { '::Gitlab::Database::PartitioningMigrationHelpers::BackfillPartitionedTable' }
      let(:sub_batch_size) { described_class::SUB_BATCH_SIZE }
      let(:pause_seconds) { described_class::PAUSE_SECONDS }
      let!(:first_id) { source_model.create!(name: 'Bob', age: 20).id }
      let!(:second_id) { source_model.create!(name: 'Alice', age: 30).id }
      let!(:third_id) { source_model.create!(name: 'Sam', age: 40).id }

      before do
        stub_const("#{described_class.name}::BATCH_SIZE", 2)

        expect(migration).to receive(:queue_background_migration_jobs_by_range_at_intervals).and_call_original
      end

      it 'enqueues jobs to copy each batch of data' do
        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        Sidekiq::Testing.fake! do
          migration.enqueue_partitioning_data_migration source_table

          expect(BackgroundMigrationWorker.jobs.size).to eq(2)

          first_job_arguments = [first_id, second_id, source_table.to_s, partitioned_table, 'id']
          expect(BackgroundMigrationWorker.jobs[0]['args']).to eq([migration_class, first_job_arguments])

          second_job_arguments = [third_id, third_id, source_table.to_s, partitioned_table, 'id']
          expect(BackgroundMigrationWorker.jobs[1]['args']).to eq([migration_class, second_job_arguments])
        end
      end
    end
  end

  describe '#cleanup_partitioning_data_migration' do
    context 'when the table is not allowed' do
      let(:source_table) { :this_table_is_not_allowed }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

        expect do
          migration.cleanup_partitioning_data_migration source_table
        end.to raise_error(/#{source_table} is not allowed for use/)
      end
    end

    context 'when tracking records exist in the background_migration_jobs table' do
      let(:migration_class) { 'Gitlab::Database::PartitioningMigrationHelpers::BackfillPartitionedTable' }
      let!(:job1) { create(:background_migration_job, class_name: migration_class, arguments: [1, 10, source_table]) }
      let!(:job2) { create(:background_migration_job, class_name: migration_class, arguments: [11, 20, source_table]) }
      let!(:job3) { create(:background_migration_job, class_name: migration_class, arguments: [1, 10, 'other_table']) }

      it 'deletes those pertaining to the given table' do
        expect { migration.cleanup_partitioning_data_migration(source_table) }
          .to change { ::Gitlab::Database::BackgroundMigrationJob.count }.from(3).to(1)

        remaining_record = ::Gitlab::Database::BackgroundMigrationJob.first
        expect(remaining_record).to have_attributes(class_name: migration_class, arguments: [1, 10, 'other_table'])
      end
    end
  end

  describe '#create_hash_partitions' do
    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{partitioned_table}
          (id serial not null, some_id integer not null, PRIMARY KEY (id, some_id))
          PARTITION BY HASH (some_id);
      SQL
    end

    it 'creates partitions for the full hash space (8 partitions)' do
      partitions = 8

      migration.create_hash_partitions(partitioned_table, partitions)

      (0..partitions - 1).each do |partition|
        partition_name = "#{partitioned_table}_#{"%01d" % partition}"
        expect_hash_partition_of(partition_name, partitioned_table, partitions, partition)
      end
    end

    it 'creates partitions for the full hash space (16 partitions)' do
      partitions = 16

      migration.create_hash_partitions(partitioned_table, partitions)

      (0..partitions - 1).each do |partition|
        partition_name = "#{partitioned_table}_#{"%02d" % partition}"
        expect_hash_partition_of(partition_name, partitioned_table, partitions, partition)
      end
    end
  end

  describe '#finalize_backfilling_partitioned_table' do
    let(:source_column) { 'id' }

    context 'when the table is not allowed' do
      let(:source_table) { :this_table_is_not_allowed }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

        expect do
          migration.finalize_backfilling_partitioned_table source_table
        end.to raise_error(/#{source_table} is not allowed for use/)
      end
    end

    context 'when the partitioned table does not exist' do
      it 'raises an error' do
        expect(migration).to receive(:table_exists?).with(partitioned_table).and_return(false)

        expect do
          migration.finalize_backfilling_partitioned_table source_table
        end.to raise_error(/could not find partitioned table for #{source_table}/)
      end
    end

    context 'finishing pending background migration jobs' do
      let(:source_table_double) { double('table name') }
      let(:raw_arguments) { [1, 50_000, source_table_double, partitioned_table, source_column] }
      let(:background_job) { double('background job', args: ['background jobs', raw_arguments]) }

      before do
        allow(migration).to receive(:table_exists?).with(partitioned_table).and_return(true)
        allow(migration).to receive(:copy_missed_records)
        allow(migration).to receive(:execute).with(/VACUUM/)
        allow(migration).to receive(:execute).with(/^(RE)?SET/)
      end

      it 'finishes remaining jobs for the correct table' do
        expect_next_instance_of(described_class::JobArguments) do |job_arguments|
          expect(job_arguments).to receive(:source_table_name).and_call_original
        end

        expect(Gitlab::BackgroundMigration).to receive(:steal)
          .with(described_class::MIGRATION_CLASS_NAME)
          .and_yield(background_job)

        expect(source_table_double).to receive(:==).with(source_table.to_s)

        migration.finalize_backfilling_partitioned_table source_table
      end
    end

    context 'when there is missed data' do
      let(:partitioned_model) { Class.new(ActiveRecord::Base) }
      let(:timestamp) { Time.utc(2019, 12, 1, 12).round }
      let!(:record1) { source_model.create!(name: 'Bob', age: 20, created_at: timestamp, updated_at: timestamp) }
      let!(:record2) { source_model.create!(name: 'Alice', age: 30, created_at: timestamp, updated_at: timestamp) }
      let!(:record3) { source_model.create!(name: 'Sam', age: 40, created_at: timestamp, updated_at: timestamp) }
      let!(:record4) { source_model.create!(name: 'Sue', age: 50, created_at: timestamp, updated_at: timestamp) }

      let!(:pending_job1) do
        create(:background_migration_job,
               class_name: described_class::MIGRATION_CLASS_NAME,
               arguments: [record1.id, record2.id, source_table, partitioned_table, source_column])
      end

      let!(:pending_job2) do
        create(:background_migration_job,
               class_name: described_class::MIGRATION_CLASS_NAME,
               arguments: [record3.id, record3.id, source_table, partitioned_table, source_column])
      end

      let!(:succeeded_job) do
        create(:background_migration_job, :succeeded,
               class_name: described_class::MIGRATION_CLASS_NAME,
               arguments: [record4.id, record4.id, source_table, partitioned_table, source_column])
      end

      before do
        partitioned_model.primary_key = :id
        partitioned_model.table_name = partitioned_table

        allow(migration).to receive(:queue_background_migration_jobs_by_range_at_intervals)

        migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

        allow(Gitlab::BackgroundMigration).to receive(:steal)
        allow(migration).to receive(:execute).with(/VACUUM/)
        allow(migration).to receive(:execute).with(/^(RE)?SET/)
      end

      it 'idempotently cleans up after failed background migrations' do
        expect(partitioned_model.count).to eq(0)

        partitioned_model.insert(record2.attributes, unique_by: [:id, :created_at])

        expect_next_instance_of(Gitlab::Database::PartitioningMigrationHelpers::BackfillPartitionedTable) do |backfill|
          allow(backfill).to receive(:transaction_open?).and_return(false)

          expect(backfill).to receive(:perform)
            .with(record1.id, record2.id, source_table, partitioned_table, source_column)
            .and_call_original

          expect(backfill).to receive(:perform)
            .with(record3.id, record3.id, source_table, partitioned_table, source_column)
            .and_call_original
        end

        migration.finalize_backfilling_partitioned_table source_table

        expect(partitioned_model.count).to eq(3)

        [record1, record2, record3].each do |original|
          copy = partitioned_model.find(original.id)
          expect(copy.attributes).to eq(original.attributes)
        end

        expect(partitioned_model.find_by_id(record4.id)).to be_nil

        [pending_job1, pending_job2].each do |job|
          expect(job.reload).to be_succeeded
        end
      end

      it 'raises an error if no job tracking records are marked as succeeded' do
        expect_next_instance_of(Gitlab::Database::PartitioningMigrationHelpers::BackfillPartitionedTable) do |backfill|
          allow(backfill).to receive(:transaction_open?).and_return(false)

          expect(backfill).to receive(:perform).and_return(0)
        end

        expect do
          migration.finalize_backfilling_partitioned_table source_table
        end.to raise_error(/failed to update tracking record/)
      end

      it 'vacuums the table after loading is complete' do
        expect_next_instance_of(Gitlab::Database::PartitioningMigrationHelpers::BackfillPartitionedTable) do |backfill|
          allow(backfill).to receive(:perform).and_return(1)
        end

        expect(migration).to receive(:disable_statement_timeout).and_call_original
        expect(migration).to receive(:execute).with("VACUUM FREEZE ANALYZE #{partitioned_table}")

        migration.finalize_backfilling_partitioned_table source_table
      end
    end
  end

  describe '#replace_with_partitioned_table' do
    let(:archived_table) { "#{source_table}_archived" }

    before do
      migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date
    end

    it 'replaces the original table with the partitioned table' do
      expect(table_type(source_table)).to eq('normal')
      expect(table_type(partitioned_table)).to eq('partitioned')
      expect(table_type(archived_table)).to be_nil

      expect_table_to_be_replaced { migration.replace_with_partitioned_table(source_table) }

      expect(table_type(source_table)).to eq('partitioned')
      expect(table_type(archived_table)).to eq('normal')
      expect(table_type(partitioned_table)).to be_nil
    end

    it 'moves the trigger from the original table to the new table' do
      expect_function_to_exist(function_name)
      expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])

      expect_table_to_be_replaced { migration.replace_with_partitioned_table(source_table) }

      expect_function_to_exist(function_name)
      expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])
    end

    def expect_table_to_be_replaced(&block)
      super(original_table: source_table, replacement_table: partitioned_table, archived_table: archived_table, &block)
    end
  end

  describe '#rollback_replace_with_partitioned_table' do
    let(:archived_table) { "#{source_table}_archived" }

    before do
      migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date

      migration.replace_with_partitioned_table source_table
    end

    it 'replaces the partitioned table with the non-partitioned table' do
      expect(table_type(source_table)).to eq('partitioned')
      expect(table_type(archived_table)).to eq('normal')
      expect(table_type(partitioned_table)).to be_nil

      expect_table_to_be_replaced { migration.rollback_replace_with_partitioned_table(source_table) }

      expect(table_type(source_table)).to eq('normal')
      expect(table_type(partitioned_table)).to eq('partitioned')
      expect(table_type(archived_table)).to be_nil
    end

    it 'moves the trigger from the partitioned table to the non-partitioned table' do
      expect_function_to_exist(function_name)
      expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])

      expect_table_to_be_replaced { migration.rollback_replace_with_partitioned_table(source_table) }

      expect_function_to_exist(function_name)
      expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])
    end

    def expect_table_to_be_replaced(&block)
      super(original_table: source_table, replacement_table: archived_table, archived_table: partitioned_table, &block)
    end
  end

  describe '#drop_nonpartitioned_archive_table' do
    subject { migration.drop_nonpartitioned_archive_table source_table }

    let(:archived_table) { "#{source_table}_archived" }

    before do
      migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date
      migration.replace_with_partitioned_table source_table
    end

    it 'drops the archive table' do
      expect(table_type(archived_table)).to eq('normal')

      subject

      expect(table_type(archived_table)).to eq(nil)
    end

    it 'drops the trigger on the source table' do
      expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])

      subject

      expect_trigger_not_to_exist(source_table, trigger_name)
    end

    it 'drops the sync function' do
      expect_function_to_exist(function_name)

      subject

      expect_function_not_to_exist(function_name)
    end
  end

  describe '#create_trigger_to_sync_tables' do
    subject { migration.create_trigger_to_sync_tables(source_table, target_table, :id) }

    let(:target_table) { "#{source_table}_copy" }

    before do
      migration.create_table target_table do |t|
        t.string :name, null: false
        t.integer :age, null: false
        t.datetime partition_column
        t.datetime :updated_at
      end
    end

    it 'creates the sync function' do
      expect_function_not_to_exist(function_name)

      subject

      expect_function_to_exist(function_name)
    end

    it 'installs the trigger' do
      expect_trigger_not_to_exist(source_table, trigger_name)

      subject

      expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])
    end
  end

  def filter_columns_by_name(columns, names)
    columns.reject { |c| names.include?(c.name) }
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "a measurable object" do
  context 'when the table is not allowed' do
    let(:source_table) { :_test_this_table_is_not_allowed }

    it 'raises an error' do
      expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

      expect do
        subject
      end.to raise_error(/#{source_table} is not allowed for use/)
    end
  end

  context 'when run inside a transaction block' do
    it 'raises an error' do
      expect(migration).to receive(:transaction_open?).and_return(true)

      expect do
        subject
      end.to raise_error(/can not be run inside a transaction/)
    end
  end

  context 'when the given table does not have a primary key' do
    it 'raises an error' do
      migration.execute(<<~SQL)
        ALTER TABLE #{source_table}
        DROP CONSTRAINT #{source_table}_pkey
      SQL

      expect do
        subject
      end.to raise_error(/primary key not defined for #{source_table}/)
    end
  end

  it 'creates the partitioned table with the same non-key columns' do
    subject

    copied_columns = filter_columns_by_name(connection.columns(partitioned_table), new_primary_key)
    original_columns = filter_columns_by_name(connection.columns(source_table), new_primary_key)

    expect(copied_columns).to match_array(original_columns)
  end

  it 'removes the default from the primary key column' do
    subject

    pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

    expect(pk_column.default_function).to be_nil
  end

  describe 'constructing the partitioned table' do
    it 'creates a table partitioned by the proper column' do
      subject

      expect(connection.table_exists?(partitioned_table)).to be(true)
      expect(connection.primary_key(partitioned_table)).to eq(new_primary_key)

      expect_table_partitioned_by(partitioned_table, [partition_column_name])
    end

    it 'requires the migration helper to be run in DDL mode' do
      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_ddl_mode!)

      subject

      expect(connection.table_exists?(partitioned_table)).to be(true)
      expect(connection.primary_key(partitioned_table)).to eq(new_primary_key)

      expect_table_partitioned_by(partitioned_table, [partition_column_name])
    end

    it 'changes the primary key datatype to bigint' do
      subject

      pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

      expect(pk_column.sql_type).to eq('bigint')
    end

    it 'removes the default from the primary key column' do
      subject

      pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

      expect(pk_column.default_function).to be_nil
    end

    it 'creates the partitioned table with the same non-key columns' do
      subject

      copied_columns = filter_columns_by_name(connection.columns(partitioned_table), new_primary_key)
      original_columns = filter_columns_by_name(connection.columns(source_table), new_primary_key)

      expect(copied_columns).to match_array(original_columns)
    end
  end

  describe 'keeping data in sync with the partitioned table' do
    before do
      partitioned_model.primary_key = :id
      partitioned_model.table_name = partitioned_table
    end

    it 'creates a trigger function on the original table' do
      expect_function_not_to_exist(function_name)
      expect_trigger_not_to_exist(source_table, trigger_name)

      subject

      expect_function_to_exist(function_name)
      expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])
    end

    it 'syncs inserts to the partitioned tables' do
      subject

      expect(partitioned_model.count).to eq(0)

      first_record = source_model.create!(name: 'Bob', age: 20, created_at: timestamp, external_id: 1, updated_at: timestamp)
      second_record = source_model.create!(name: 'Alice', age: 30, created_at: timestamp, external_id: 2, updated_at: timestamp)

      expect(partitioned_model.count).to eq(2)
      expect(partitioned_model.find(first_record.id).attributes).to eq(first_record.attributes)
      expect(partitioned_model.find(second_record.id).attributes).to eq(second_record.attributes)
    end

    it 'syncs updates to the partitioned tables' do
      subject

      first_record = source_model.create!(name: 'Bob', age: 20, created_at: timestamp, external_id: 1, updated_at: timestamp)
      second_record = source_model.create!(name: 'Alice', age: 30, created_at: timestamp, external_id: 2, updated_at: timestamp)

      expect(partitioned_model.count).to eq(2)

      first_copy = partitioned_model.find(first_record.id)
      second_copy = partitioned_model.find(second_record.id)

      expect(first_copy.attributes).to eq(first_record.attributes)
      expect(second_copy.attributes).to eq(second_record.attributes)

      first_record.update!(age: 21, updated_at: timestamp + 1.hour, external_id: 3)

      expect(partitioned_model.count).to eq(2)
      expect(first_copy.reload.attributes).to eq(first_record.attributes)
      expect(second_copy.reload.attributes).to eq(second_record.attributes)
    end

    it 'syncs deletes to the partitioned tables' do
      subject

      first_record = source_model.create!(name: 'Bob', age: 20, created_at: timestamp, external_id: 1, updated_at: timestamp)
      second_record = source_model.create!(name: 'Alice', age: 30, created_at: timestamp, external_id: 2, updated_at: timestamp)

      expect(partitioned_model.count).to eq(2)

      first_record.destroy!

      expect(partitioned_model.count).to eq(1)
      expect(partitioned_model.find_by_id(first_record.id)).to be_nil
      expect(partitioned_model.find(second_record.id).attributes).to eq(second_record.attributes)
    end
  end
end

RSpec.describe Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers, feature_category: :database do
  include Database::PartitioningHelpers
  include Database::TriggerHelpers
  include Database::TableSchemaHelpers
  include MigrationsHelpers

  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let_it_be(:connection) { ActiveRecord::Base.connection }

  let(:source_table) { :_test_original_table }
  let(:partitioned_table) { :_test_migration_partitioned_table }
  let(:function_name) { :_test_migration_function_name }
  let(:trigger_name) { :_test_migration_trigger_name }
  let(:partition_column2) { 'external_id' }
  let(:partition_column) { 'created_at' }
  let(:min_date) { Date.new(2019, 12) }
  let(:max_date) { Date.new(2020, 3) }
  let(:source_model) { Class.new(ActiveRecord::Base) }

  before do
    allow(migration).to receive(:puts)

    migration.create_table source_table do |t|
      t.string :name, null: false
      t.integer :age, null: false
      t.integer partition_column2
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

  context 'list partitioning conversion helpers' do
    shared_examples_for 'delegates to ConvertTable' do
      let(:extra_options) { {} }
      it 'throws an error if in a transaction' do
        allow(migration).to receive(:transaction_open?).and_return(true)
        expect { migrate }.to raise_error(/cannot be run inside a transaction/)
      end

      it 'delegates to a method on List::ConvertTable' do
        expect_next_instance_of(
          Gitlab::Database::Partitioning::List::ConvertTable,
          migration_context: migration,
          table_name: source_table,
          parent_table_name: partitioned_table,
          partitioning_column: partition_column,
          zero_partition_value: min_date,
          **extra_options
        ) do |converter|
          expect(converter).to receive(expected_method)
        end

        migrate
      end
    end

    describe '#convert_table_to_first_list_partition' do
      it_behaves_like 'delegates to ConvertTable' do
        let(:lock_tables) { [source_table] }
        let(:expected_method) { :partition }
        let(:migrate) do
          migration.convert_table_to_first_list_partition(
            table_name: source_table,
            partitioning_column: partition_column,
            parent_table_name: partitioned_table,
            initial_partitioning_value: min_date,
            lock_tables: lock_tables
          )
        end
      end
    end

    describe '#revert_converting_table_to_first_list_partition' do
      it_behaves_like 'delegates to ConvertTable' do
        let(:expected_method) { :revert_partitioning }
        let(:migrate) do
          migration.revert_converting_table_to_first_list_partition(
            table_name: source_table,
            partitioning_column: partition_column,
            parent_table_name: partitioned_table,
            initial_partitioning_value: min_date
          )
        end
      end
    end

    describe '#prepare_constraint_for_list_partitioning' do
      it_behaves_like 'delegates to ConvertTable' do
        let(:expected_method) { :prepare_for_partitioning }
        let(:migrate) do
          migration.prepare_constraint_for_list_partitioning(
            table_name: source_table,
            partitioning_column: partition_column,
            parent_table_name: partitioned_table,
            initial_partitioning_value: min_date,
            async: false
          )
        end
      end
    end

    describe '#revert_preparing_constraint_for_list_partitioning' do
      it_behaves_like 'delegates to ConvertTable' do
        let(:expected_method) { :revert_preparation_for_partitioning }
        let(:migrate) do
          migration.revert_preparing_constraint_for_list_partitioning(
            table_name: source_table,
            partitioning_column: partition_column,
            parent_table_name: partitioned_table,
            initial_partitioning_value: min_date
          )
        end
      end
    end
  end

  describe '#partition_table_by_int_range' do
    let(:old_primary_key) { 'id' }
    let(:new_primary_key) { ['id', partition_column2] }
    let(:partition_column_name) { partition_column2 }
    let(:partitioned_model) { Class.new(ActiveRecord::Base) }
    let(:timestamp) { Time.utc(2019, 12, 1, 12).round }
    let(:partition_size) { 500 }

    subject { migration.partition_table_by_int_range(source_table, partition_column2, partition_size: partition_size, primary_key: ['id', partition_column2]) }

    include_examples "a measurable object"

    context 'simulates the merge_request_diff_commits migration' do
      let(:table_name) { '_test_merge_request_diff_commits' }
      let(:partition_column_name) { 'relative_order' }
      let(:partition_size) { 2 }
      let(:partitions) do
        {
          '1' => %w[1 3],
          '3' => %w[3 5],
          '5' => %w[5 7],
          '7' => %w[7 9],
          '9' => %w[9 11],
          '11' => %w[11 13]
        }
      end

      let(:buffer_partitions) do
        {
          '13' => %w[13 15],
          '15' => %w[15 17],
          '17' => %w[17 19],
          '19' => %w[19 21],
          '21' => %w[21 23],
          '23' => %w[23 25]
        }
      end

      let(:new_table_defition) do
        {
          new_path: { default: 'test', null: true, sql_type: 'text' },
          merge_request_diff_id: { default: nil, null: false, sql_type: 'bigint' },
          relative_order: { default: nil, null: false, sql_type: 'integer' }
        }
      end

      let(:primary_key) { %w[merge_request_diff_id relative_order] }

      before do
        migration.create_table table_name, primary_key: primary_key do |t|
          t.integer :merge_request_diff_id, null: false, default: 1
          t.integer :relative_order, null: false
          t.text :new_path, null: true, default: 'test'
        end

        source_model.table_name = table_name
      end

      it 'creates the partitions' do
        migration.partition_table_by_int_range(table_name, partition_column_name, partition_size: partition_size, primary_key: primary_key)

        expect_range_partitions_for(partitioned_table, partitions.merge(buffer_partitions))
      end

      it 'creates a composite primary key' do
        migration.partition_table_by_int_range(
          table_name, partition_column_name, partition_size: partition_size, primary_key: primary_key
        )

        expect(connection.primary_key(:_test_migration_partitioned_table))
          .to eql(%w[merge_request_diff_id relative_order])
      end

      it 'applies the correct column schema for the new table' do
        migration.partition_table_by_int_range(
          table_name, partition_column_name, partition_size: partition_size, primary_key: primary_key
        )

        columns = connection.columns(:_test_migration_partitioned_table)

        columns.each do |column|
          column_name = column.name.to_sym

          expect(column.default).to eql(new_table_defition[column_name][:default])
          expect(column.null).to eql(new_table_defition[column_name][:null])
          expect(column.sql_type).to eql(new_table_defition[column_name][:sql_type])
        end
      end

      it 'creates multiple partitions' do
        migration.partition_table_by_int_range(
          table_name, partition_column_name, partition_size: 500, primary_key: primary_key
        )

        expect_range_partitions_for(partitioned_table, {
          '1' => %w[1 501],
          '501' => %w[501 1001],
          '1001' => %w[1001 1501],
          '1501' => %w[1501 2001],
          '2001' => %w[2001 2501],
          '2501' => %w[2501 3001],
          '3001' => %w[3001 3501],
          '3501' => %w[3501 4001],
          '4001' => %w[4001 4501],
          '4501' => %w[4501 5001],
          '5001' => %w[5001 5501],
          '5501' => %w[5501 6001]
        })
      end

      context 'when the table is not empty' do
        before do
          source_model.create!(merge_request_diff_id: 1, relative_order: 7, new_path: 'new_path')
        end

        let(:partition_size) { 2 }

        let(:partitions) do
          {
            '1' => %w[1 3],
            '3' => %w[3 5],
            '5' => %w[5 7]
          }
        end

        let(:buffer_partitions) do
          {
            '7' => %w[7 9],
            '9' => %w[9 11],
            '11' => %w[11 13],
            '13' => %w[13 15],
            '15' => %w[15 17],
            '17' => %w[17 19]
          }
        end

        it 'defaults the min_id to 1 and the max_id to 7' do
          migration.partition_table_by_int_range(
            table_name, partition_column_name, partition_size: partition_size, primary_key: primary_key
          )

          expect_range_partitions_for(partitioned_table, partitions.merge(buffer_partitions))
        end
      end
    end

    context 'when an invalid partition column is given' do
      let(:invalid_column) { :_this_is_not_real }

      it 'raises an error' do
        expect do
          migration.partition_table_by_int_range(
            source_table, invalid_column, partition_size: partition_size, primary_key: ['id']
          )
        end.to raise_error(/partition column #{invalid_column} does not exist/)
      end
    end

    context 'when partition_size is less than 1' do
      let(:partition_size) { 1 }

      it 'raises an error' do
        expect do
          subject
        end.to raise_error(/partition_size must be greater than 1/)
      end
    end

    context 'when the partitioned table already exists' do
      before do
        migration.send(
          :create_range_id_partitioned_copy,
          source_table,
          migration.send(:make_partitioned_table_name, source_table),
          connection.columns(source_table).find { |c| c.name == partition_column2 },
          connection.columns(source_table).select { |c| new_primary_key.include?(c.name) }
        )
      end

      it 'raises an error' do
        expect(Gitlab::AppLogger).to receive(:warn).with(/Partitioned table not created because it already exists/)
        expect { subject }.not_to raise_error
      end
    end
  end

  describe '#partition_table_by_date' do
    let(:partition_column) { 'created_at' }
    let(:old_primary_key) { 'id' }
    let(:new_primary_key) { [old_primary_key, partition_column] }
    let(:partition_column_name) { 'created_at' }
    let(:partitioned_model) { Class.new(ActiveRecord::Base) }
    let(:timestamp) { Time.utc(2019, 12, 1, 12).round }

    subject { migration.partition_table_by_date source_table, partition_column, min_date: min_date, max_date: max_date }

    include_examples "a measurable object"

    context 'when the the max_date is less than the min_date' do
      let(:max_date) { Time.utc(2019, 6) }

      it 'raises an error' do
        expect do
          migration.partition_table_by_date(
            source_table, partition_column, min_date: min_date, max_date: max_date
          )
        end.to raise_error(/max_date #{max_date} must be greater than min_date #{min_date}/)
      end
    end

    context 'when the max_date is equal to the min_date' do
      let(:max_date) { min_date }

      it 'raises an error' do
        expect do
          migration.partition_table_by_date(
            source_table, partition_column, min_date: min_date, max_date: max_date
          )
        end.to raise_error(/max_date #{max_date} must be greater than min_date #{min_date}/)
      end
    end

    context 'when an invalid partition column is given' do
      let(:invalid_column) { :_this_is_not_real }

      it 'raises an error' do
        expect do
          migration.partition_table_by_date(
            source_table, invalid_column, min_date: min_date, max_date: max_date
          )
        end.to raise_error(/partition column #{invalid_column} does not exist/)
      end
    end

    describe 'constructing the partitioned table' do
      context 'with a non-integer primary key datatype' do
        before do
          connection.create_table non_int_table, id: false do |t|
            t.string :identifier, primary_key: true
            t.timestamp :created_at
          end
        end

        let(:non_int_table) { :_test_another_example }
        let(:old_primary_key) { 'identifier' }

        it 'does not change the primary key datatype' do
          migration.partition_table_by_date(
            non_int_table, partition_column, min_date: min_date, max_date: max_date
          )

          original_pk_column = connection.columns(non_int_table).find { |c| c.name == old_primary_key }
          pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

          expect(pk_column).not_to be_nil
          expect(pk_column).to eq(original_pk_column)
        end
      end

      it 'creates a partition spanning over each month in the range given' do
        migration.partition_table_by_date(
          source_table, partition_column, min_date: min_date, max_date: max_date
        )

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
            expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:with_suppressed).and_yield

            migration.partition_table_by_date(
              source_table, partition_column, max_date: max_date
            )

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
            expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:with_suppressed).and_yield

            migration.partition_table_by_date(source_table, partition_column, max_date: max_date)

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
            migration.partition_table_by_date(source_table, partition_column, min_date: min_date)

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
            migration.partition_table_by_date(source_table, partition_column)

            expect_range_partitions_for(partitioned_table, {
              '000000' => ['MINVALUE', "'2020-05-01 00:00:00'"],
              '202005' => ["'2020-05-01 00:00:00'", "'2020-06-01 00:00:00'"],
              '202006' => ["'2020-06-01 00:00:00'", "'2020-07-01 00:00:00'"]
            })
          end
        end
      end
    end
  end

  describe '#drop_partitioned_table_for' do
    let(:expected_tables) do
      %w[000000 201912 202001 202002].map { |suffix| "#{Gitlab::Database::DYNAMIC_PARTITIONS_SCHEMA}.#{partitioned_table}_#{suffix}" }.unshift(partitioned_table)
    end

    let(:migration_class) { 'Gitlab::Database::PartitioningMigrationHelpers::BackfillPartitionedTable' }

    context 'when the table is not allowed' do
      let(:source_table) { :_test_this_table_is_not_allowed }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

        expect do
          migration.drop_partitioned_table_for(source_table)
        end.to raise_error(/#{source_table} is not allowed for use/)
      end
    end

    it 'drops the trigger syncing to the partitioned table' do
      migration.partition_table_by_date(
        source_table, partition_column, min_date: min_date, max_date: max_date
      )

      expect_function_to_exist(function_name)
      expect_valid_function_trigger(source_table, trigger_name, function_name, after: %w[delete insert update])

      migration.drop_partitioned_table_for(source_table)

      expect_function_not_to_exist(function_name)
      expect_trigger_not_to_exist(source_table, trigger_name)
    end

    it 'drops the partitioned copy and all partitions' do
      migration.partition_table_by_date(
        source_table, partition_column, min_date: min_date, max_date: max_date
      )

      expected_tables.each do |table|
        expect(connection.table_exists?(table)).to be(true)
      end

      migration.drop_partitioned_table_for(source_table)

      expected_tables.each do |table|
        expect(connection.table_exists?(table)).to be(false)
      end
    end
  end

  describe '#enqueue_partitioning_data_migration' do
    context 'when the table is not allowed' do
      let(:source_table) { :_test_this_table_is_not_allowed }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

        expect do
          migration.enqueue_partitioning_data_migration(source_table)
        end.to raise_error(/#{source_table} is not allowed for use/)
      end
    end

    context 'when run inside a transaction block' do
      it 'raises an error' do
        expect(migration).to receive(:transaction_open?).and_return(true)

        expect do
          migration.enqueue_partitioning_data_migration(source_table)
        end.to raise_error(/can not be run inside a transaction/)
      end
    end

    context 'when records exist in the source table' do
      let(:migration_class) { described_class::MIGRATION }
      let(:sub_batch_size) { described_class::SUB_BATCH_SIZE }
      let!(:first_id) { source_model.create!(name: 'Bob', age: 20).id }
      let!(:second_id) { source_model.create!(name: 'Alice', age: 30).id }
      let!(:third_id) { source_model.create!(name: 'Sam', age: 40).id }

      before do
        stub_const("#{described_class.name}::BATCH_SIZE", 2)
        stub_const("#{described_class.name}::SUB_BATCH_SIZE", 1)
      end

      it 'enqueues jobs to copy each batch of data' do
        migration.partition_table_by_date(
          source_table, partition_column, min_date: min_date, max_date: max_date
        )

        Sidekiq::Testing.fake! do
          migration.enqueue_partitioning_data_migration(source_table)

          expect(migration_class).to have_scheduled_batched_migration(
            table_name: source_table,
            column_name: :id,
            job_arguments: [partitioned_table],
            batch_size: described_class::BATCH_SIZE,
            sub_batch_size: described_class::SUB_BATCH_SIZE
          )
        end
      end
    end
  end

  describe '#cleanup_partitioning_data_migration' do
    context 'when the table is not allowed' do
      let(:source_table) { :_test_this_table_is_not_allowed }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

        expect do
          migration.cleanup_partitioning_data_migration(source_table)
        end.to raise_error(/#{source_table} is not allowed for use/)
      end
    end

    context 'when tracking records exist in the batched_background_migrations table' do
      let(:migration_class) { described_class::MIGRATION }

      before do
        create(
          :batched_background_migration,
          job_class_name: migration_class,
          table_name: source_table,
          column_name: :id,
          job_arguments: [partitioned_table]
        )

        create(
          :batched_background_migration,
          job_class_name: migration_class,
          table_name: 'other_table',
          column_name: :id,
          job_arguments: ['other_table_partitioned']
        )
      end

      it 'deletes those pertaining to the given table' do
        expect { migration.cleanup_partitioning_data_migration(source_table) }
          .to change { ::Gitlab::Database::BackgroundMigration::BatchedMigration.count }.by(-1)

        expect(::Gitlab::Database::BackgroundMigration::BatchedMigration.where(table_name: 'other_table').any?)
          .to be_truthy

        expect(::Gitlab::Database::BackgroundMigration::BatchedMigration.where(table_name: source_table).any?)
          .to be_falsy
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
    let(:source_column) { :id }

    context 'when the table is not allowed' do
      let(:source_table) { :_test_this_table_is_not_allowed }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_allowed).with(source_table).and_call_original

        expect do
          migration.finalize_backfilling_partitioned_table(source_table)
        end.to raise_error(/#{source_table} is not allowed for use/)
      end
    end

    context 'when the partitioned table does not exist' do
      it 'raises an error' do
        expect(migration).to receive(:table_exists?).with(partitioned_table).and_return(false)

        expect do
          migration.finalize_backfilling_partitioned_table(source_table)
        end.to raise_error(/could not find partitioned table for #{source_table}/)
      end
    end

    context 'finishing pending batched background migration jobs' do
      let(:source_table_double) { double('table name') }
      let(:raw_arguments) { [1, 50_000, source_table_double, partitioned_table, source_column] }
      let(:background_job) { double('background job', args: ['background jobs', raw_arguments]) }
      let(:bbm_arguments) do
        {
          job_class_name: described_class::MIGRATION,
          table_name: source_table,
          column_name: connection.primary_key(source_table),
          job_arguments: [partitioned_table]
        }
      end

      before do
        allow(migration).to receive(:table_exists?).with(partitioned_table).and_return(true)
        allow(migration).to receive(:execute).with(/VACUUM/)
        allow(migration).to receive(:execute).with(/^(RE)?SET/)
      end

      it 'ensures finishing of remaining jobs and vacuums the partitioned table' do
        expect(migration).to receive(:ensure_batched_background_migration_is_finished)
          .with(bbm_arguments)

        expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:with_suppressed).and_yield
        expect(migration).to receive(:disable_statement_timeout).and_call_original
        expect(migration).to receive(:execute).with("VACUUM FREEZE ANALYZE #{partitioned_table}")

        migration.finalize_backfilling_partitioned_table(source_table)
      end
    end
  end

  describe '#replace_with_partitioned_table' do
    let(:archived_table) { "#{source_table}_archived" }

    before do
      migration.partition_table_by_date(
        source_table, partition_column, min_date: min_date, max_date: max_date
      )
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
      migration.partition_table_by_date(
        source_table, partition_column, min_date: min_date, max_date: max_date
      )

      migration.replace_with_partitioned_table(source_table)
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
    subject { migration.drop_nonpartitioned_archive_table(source_table) }

    let(:archived_table) { "#{source_table}_archived" }

    before do
      migration.partition_table_by_date(
        source_table, partition_column, min_date: min_date, max_date: max_date
      )

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

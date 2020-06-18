# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers do
  include PartitioningHelpers
  include TriggerHelpers

  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let_it_be(:connection) { ActiveRecord::Base.connection }
  let(:template_table) { :audit_events }
  let(:partitioned_table) { '_test_migration_partitioned_table' }
  let(:function_name) { '_test_migration_function_name' }
  let(:trigger_name) { '_test_migration_trigger_name' }
  let(:partition_column) { 'created_at' }
  let(:min_date) { Date.new(2019, 12) }
  let(:max_date) { Date.new(2020, 3) }

  before do
    allow(migration).to receive(:puts)
    allow(migration).to receive(:transaction_open?).and_return(false)
    allow(migration).to receive(:partitioned_table_name).and_return(partitioned_table)
    allow(migration).to receive(:sync_function_name).and_return(function_name)
    allow(migration).to receive(:sync_trigger_name).and_return(trigger_name)
    allow(migration).to receive(:assert_table_is_whitelisted)
  end

  describe '#partition_table_by_date' do
    let(:partition_column) { 'created_at' }
    let(:old_primary_key) { 'id' }
    let(:new_primary_key) { [old_primary_key, partition_column] }

    context 'when the table is not whitelisted' do
      let(:template_table) { :this_table_is_not_whitelisted }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_whitelisted).with(template_table).and_call_original

        expect do
          migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/#{template_table} is not whitelisted for use/)
      end
    end

    context 'when run inside a transaction block' do
      it 'raises an error' do
        expect(migration).to receive(:transaction_open?).and_return(true)

        expect do
          migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/can not be run inside a transaction/)
      end
    end

    context 'when the the max_date is less than the min_date' do
      let(:max_date) { Time.utc(2019, 6) }

      it 'raises an error' do
        expect do
          migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/max_date #{max_date} must be greater than min_date #{min_date}/)
      end
    end

    context 'when the max_date is equal to the min_date' do
      let(:max_date) { min_date }

      it 'raises an error' do
        expect do
          migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/max_date #{max_date} must be greater than min_date #{min_date}/)
      end
    end

    context 'when the given table does not have a primary key' do
      let(:template_table) { :_partitioning_migration_helper_test_table }
      let(:partition_column) { :some_field }

      it 'raises an error' do
        migration.create_table template_table, id: false do |t|
          t.integer :id
          t.datetime partition_column
        end

        expect do
          migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/primary key not defined for #{template_table}/)
      end
    end

    context 'when an invalid partition column is given' do
      let(:partition_column) { :_this_is_not_real }

      it 'raises an error' do
        expect do
          migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/partition column #{partition_column} does not exist/)
      end
    end

    describe 'constructing the partitioned table' do
      it 'creates a table partitioned by the proper column' do
        migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        expect(connection.table_exists?(partitioned_table)).to be(true)
        expect(connection.primary_key(partitioned_table)).to eq(new_primary_key)

        expect_table_partitioned_by(partitioned_table, [partition_column])
      end

      it 'changes the primary key datatype to bigint' do
        migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

        expect(pk_column.sql_type).to eq('bigint')
      end

      context 'with a non-integer primary key datatype' do
        before do
          connection.create_table :another_example, id: false do |t|
            t.string :identifier, primary_key: true
            t.timestamp :created_at
          end
        end

        let(:template_table) { :another_example }
        let(:old_primary_key) { 'identifier' }

        it 'does not change the primary key datatype' do
          migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

          original_pk_column = connection.columns(template_table).find { |c| c.name == old_primary_key }
          pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

          expect(pk_column).not_to be_nil
          expect(pk_column).to eq(original_pk_column)
        end
      end

      it 'removes the default from the primary key column' do
        migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

        expect(pk_column.default_function).to be_nil
      end

      it 'creates the partitioned table with the same non-key columns' do
        migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        copied_columns = filter_columns_by_name(connection.columns(partitioned_table), new_primary_key)
        original_columns = filter_columns_by_name(connection.columns(template_table), new_primary_key)

        expect(copied_columns).to match_array(original_columns)
      end

      it 'creates a partition spanning over each month in the range given' do
        migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        expect_range_partition_of("#{partitioned_table}_000000", partitioned_table, 'MINVALUE', "'2019-12-01 00:00:00'")
        expect_range_partition_of("#{partitioned_table}_201912", partitioned_table, "'2019-12-01 00:00:00'", "'2020-01-01 00:00:00'")
        expect_range_partition_of("#{partitioned_table}_202001", partitioned_table, "'2020-01-01 00:00:00'", "'2020-02-01 00:00:00'")
        expect_range_partition_of("#{partitioned_table}_202002", partitioned_table, "'2020-02-01 00:00:00'", "'2020-03-01 00:00:00'")
      end
    end

    describe 'keeping data in sync with the partitioned table' do
      let(:template_table) { :todos }
      let(:model) { Class.new(ActiveRecord::Base) }
      let(:timestamp) { Time.utc(2019, 12, 1, 12).round }

      before do
        model.primary_key = :id
        model.table_name = partitioned_table
      end

      it 'creates a trigger function on the original table' do
        expect_function_not_to_exist(function_name)
        expect_trigger_not_to_exist(template_table, trigger_name)

        migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        expect_function_to_exist(function_name)
        expect_valid_function_trigger(template_table, trigger_name, function_name, after: %w[delete insert update])
      end

      it 'syncs inserts to the partitioned tables' do
        migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        expect(model.count).to eq(0)

        first_todo = create(:todo, created_at: timestamp, updated_at: timestamp)
        second_todo = create(:todo, created_at: timestamp, updated_at: timestamp)

        expect(model.count).to eq(2)
        expect(model.find(first_todo.id).attributes).to eq(first_todo.attributes)
        expect(model.find(second_todo.id).attributes).to eq(second_todo.attributes)
      end

      it 'syncs updates to the partitioned tables' do
        migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        first_todo = create(:todo, :pending, commit_id: nil, created_at: timestamp, updated_at: timestamp)
        second_todo = create(:todo, created_at: timestamp, updated_at: timestamp)

        expect(model.count).to eq(2)

        first_copy = model.find(first_todo.id)
        second_copy = model.find(second_todo.id)

        expect(first_copy.attributes).to eq(first_todo.attributes)
        expect(second_copy.attributes).to eq(second_todo.attributes)

        first_todo.update(state_event: 'done', commit_id: 'abc123', updated_at: timestamp + 1.second)

        expect(model.count).to eq(2)
        expect(first_copy.reload.attributes).to eq(first_todo.attributes)
        expect(second_copy.reload.attributes).to eq(second_todo.attributes)
      end

      it 'syncs deletes to the partitioned tables' do
        migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        first_todo = create(:todo, created_at: timestamp, updated_at: timestamp)
        second_todo = create(:todo, created_at: timestamp, updated_at: timestamp)

        expect(model.count).to eq(2)

        first_todo.destroy

        expect(model.count).to eq(1)
        expect(model.find_by_id(first_todo.id)).to be_nil
        expect(model.find(second_todo.id).attributes).to eq(second_todo.attributes)
      end
    end
  end

  describe '#drop_partitioned_table_for' do
    let(:expected_tables) do
      %w[000000 201912 202001 202002].map { |suffix| "#{partitioned_table}_#{suffix}" }.unshift(partitioned_table)
    end

    context 'when the table is not whitelisted' do
      let(:template_table) { :this_table_is_not_whitelisted }

      it 'raises an error' do
        expect(migration).to receive(:assert_table_is_whitelisted).with(template_table).and_call_original

        expect do
          migration.drop_partitioned_table_for template_table
        end.to raise_error(/#{template_table} is not whitelisted for use/)
      end
    end

    it 'drops the trigger syncing to the partitioned table' do
      migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

      expect_function_to_exist(function_name)
      expect_valid_function_trigger(template_table, trigger_name, function_name, after: %w[delete insert update])

      migration.drop_partitioned_table_for template_table

      expect_function_not_to_exist(function_name)
      expect_trigger_not_to_exist(template_table, trigger_name)
    end

    it 'drops the partitioned copy and all partitions' do
      migration.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

      expected_tables.each do |table|
        expect(connection.table_exists?(table)).to be(true)
      end

      migration.drop_partitioned_table_for template_table

      expected_tables.each do |table|
        expect(connection.table_exists?(table)).to be(false)
      end
    end
  end

  def filter_columns_by_name(columns, names)
    columns.reject { |c| names.include?(c.name) }
  end
end

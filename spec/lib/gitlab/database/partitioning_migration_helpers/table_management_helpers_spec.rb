# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::PartitioningMigrationHelpers::TableManagementHelpers do
  include PartitioningHelpers

  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let_it_be(:connection) { ActiveRecord::Base.connection }
  let(:template_table) { :audit_events }
  let(:partitioned_table) { '_test_migration_partitioned_table' }
  let(:partition_column) { 'created_at' }
  let(:min_date) { Date.new(2019, 12) }
  let(:max_date) { Date.new(2020, 3) }

  before do
    allow(model).to receive(:puts)
    allow(model).to receive(:partitioned_table_name).and_return(partitioned_table)
  end

  describe '#partition_table_by_date' do
    let(:old_primary_key) { 'id' }
    let(:new_primary_key) { [old_primary_key, partition_column] }

    context 'when the the max_date is less than the min_date' do
      let(:max_date) { Time.utc(2019, 6) }

      it 'raises an error' do
        expect do
          model.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/max_date #{max_date} must be greater than min_date #{min_date}/)
      end
    end

    context 'when the max_date is equal to the min_date' do
      let(:max_date) { min_date }

      it 'raises an error' do
        expect do
          model.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/max_date #{max_date} must be greater than min_date #{min_date}/)
      end
    end

    context 'when the given table does not have a primary key' do
      let(:template_table) { :_partitioning_migration_helper_test_table }
      let(:partition_column) { :some_field }

      it 'raises an error' do
        model.create_table template_table, id: false do |t|
          t.integer :id
          t.datetime partition_column
        end

        expect do
          model.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/primary key not defined for #{template_table}/)
      end
    end

    context 'when an invalid partition column is given' do
      let(:partition_column) { :_this_is_not_real }

      it 'raises an error' do
        expect do
          model.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date
        end.to raise_error(/partition column #{partition_column} does not exist/)
      end
    end

    context 'when a valid source table and partition column is given' do
      it 'creates a table partitioned by the proper column' do
        model.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        expect(connection.table_exists?(partitioned_table)).to be(true)
        expect(connection.primary_key(partitioned_table)).to eq(new_primary_key)

        expect_table_partitioned_by(partitioned_table, [partition_column])
      end

      it 'removes the default from the primary key column' do
        model.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        pk_column = connection.columns(partitioned_table).find { |c| c.name == old_primary_key }

        expect(pk_column.default_function).to be_nil
      end

      it 'creates the partitioned table with the same non-key columns' do
        model.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        copied_columns = filter_columns_by_name(connection.columns(partitioned_table), new_primary_key)
        original_columns = filter_columns_by_name(connection.columns(template_table), new_primary_key)

        expect(copied_columns).to match_array(original_columns)
      end

      it 'creates a partition spanning over each month in the range given' do
        model.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

        expect_range_partition_of("#{partitioned_table}_000000", partitioned_table, 'MINVALUE', "'2019-12-01 00:00:00'")
        expect_range_partition_of("#{partitioned_table}_201912", partitioned_table, "'2019-12-01 00:00:00'", "'2020-01-01 00:00:00'")
        expect_range_partition_of("#{partitioned_table}_202001", partitioned_table, "'2020-01-01 00:00:00'", "'2020-02-01 00:00:00'")
        expect_range_partition_of("#{partitioned_table}_202002", partitioned_table, "'2020-02-01 00:00:00'", "'2020-03-01 00:00:00'")
      end
    end
  end

  describe '#drop_partitioned_table_for' do
    let(:expected_tables) do
      %w[000000 201912 202001 202002].map { |suffix| "#{partitioned_table}_#{suffix}" }.unshift(partitioned_table)
    end

    it 'drops the partitioned copy and all partitions' do
      model.partition_table_by_date template_table, partition_column, min_date: min_date, max_date: max_date

      expected_tables.each do |table|
        expect(connection.table_exists?(table)).to be(true)
      end

      model.drop_partitioned_table_for template_table

      expected_tables.each do |table|
        expect(connection.table_exists?(table)).to be(false)
      end
    end
  end

  def filter_columns_by_name(columns, names)
    columns.reject { |c| names.include?(c.name) }
  end
end

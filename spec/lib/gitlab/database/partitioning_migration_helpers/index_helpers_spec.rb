# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers do
  include Database::TableSchemaHelpers

  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let(:table_name) { '_test_partitioned_table' }
  let(:column_name) { 'created_at' }
  let(:index_name) { '_test_partitioning_index_name' }
  let(:partition_schema) { 'gitlab_partitions_dynamic' }
  let(:partition1_identifier) { "#{partition_schema}.#{table_name}_202001" }
  let(:partition2_identifier) { "#{partition_schema}.#{table_name}_202002" }
  let(:partition1_index) { "index_#{table_name}_202001_#{column_name}" }
  let(:partition2_index) { "index_#{table_name}_202002_#{column_name}" }

  before do
    allow(migration).to receive(:puts)

    connection.execute(<<~SQL)
      CREATE TABLE #{table_name} (
        id serial NOT NULL,
        created_at timestamptz NOT NULL,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);

      CREATE TABLE #{partition1_identifier} PARTITION OF #{table_name}
      FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

      CREATE TABLE #{partition2_identifier} PARTITION OF #{table_name}
      FOR VALUES FROM ('2020-02-01') TO ('2020-03-01');
    SQL
  end

  describe '#add_concurrent_partitioned_index' do
    before do
      allow(migration).to receive(:index_name_exists?).with(table_name, index_name).and_return(false)

      allow(migration).to receive(:generated_index_name).and_return(partition1_index, partition2_index)

      allow(migration).to receive(:with_lock_retries).and_yield
    end

    context 'when the index does not exist on the parent table' do
      it 'creates the index on each partition, and the parent table', :aggregate_failures do
        expect(migration).to receive(:index_name_exists?).with(table_name, index_name).and_return(false)

        expect_add_concurrent_index_and_call_original(partition1_identifier, column_name, partition1_index)
        expect_add_concurrent_index_and_call_original(partition2_identifier, column_name, partition2_index)

        expect(migration).to receive(:with_lock_retries).ordered.and_yield
        expect(migration).to receive(:add_index).with(table_name, column_name, name: index_name).ordered.and_call_original

        migration.add_concurrent_partitioned_index(table_name, column_name, name: index_name)

        expect_index_to_exist(partition1_index, schema: partition_schema)
        expect_index_to_exist(partition2_index, schema: partition_schema)
        expect_index_to_exist(index_name)
      end

      def expect_add_concurrent_index_and_call_original(table, column, index)
        expect(migration).to receive(:add_concurrent_index).ordered.with(table, column, name: index)
          .and_wrap_original { |_, table, column, options| connection.add_index(table, column, **options) }
      end
    end

    context 'when the index exists on the parent table' do
      it 'does not attempt to create any indexes', :aggregate_failures do
        expect(migration).to receive(:index_name_exists?).with(table_name, index_name).and_return(true)

        expect(migration).not_to receive(:add_concurrent_index)
        expect(migration).not_to receive(:with_lock_retries)
        expect(migration).not_to receive(:add_index)

        migration.add_concurrent_partitioned_index(table_name, column_name, name: index_name)
      end
    end

    context 'when additional index options are given' do
      before do
        connection.execute(<<~SQL)
          DROP TABLE #{partition2_identifier}
        SQL
      end

      it 'forwards them to the index helper methods', :aggregate_failures do
        expect(migration).to receive(:add_concurrent_index)
          .with(partition1_identifier, column_name, name: partition1_index, where: 'x > 0', unique: true)

        expect(migration).to receive(:add_index)
          .with(table_name, column_name, name: index_name, where: 'x > 0', unique: true)

        migration.add_concurrent_partitioned_index(table_name, column_name,
            name: index_name, where: 'x > 0', unique: true)
      end
    end

    context 'when a name argument for the index is not given' do
      it 'raises an error', :aggregate_failures do
        expect(migration).not_to receive(:add_concurrent_index)
        expect(migration).not_to receive(:with_lock_retries)
        expect(migration).not_to receive(:add_index)

        expect do
          migration.add_concurrent_partitioned_index(table_name, column_name)
        end.to raise_error(ArgumentError, /A name is required for indexes added to partitioned tables/)
      end
    end

    context 'when the given table is not a partitioned table' do
      before do
        allow(Gitlab::Database::PostgresPartitionedTable).to receive(:find_by_name_in_current_schema)
          .with(table_name).and_return(nil)
      end

      it 'raises an error', :aggregate_failures do
        expect(migration).not_to receive(:add_concurrent_index)
        expect(migration).not_to receive(:with_lock_retries)
        expect(migration).not_to receive(:add_index)

        expect do
          migration.add_concurrent_partitioned_index(table_name, column_name, name: index_name)
        end.to raise_error(ArgumentError, /#{table_name} is not a partitioned table/)
      end
    end
  end

  describe '#remove_concurrent_partitioned_index_by_name' do
    context 'when the index exists' do
      before do
        connection.execute(<<~SQL)
          CREATE INDEX #{partition1_index} ON #{partition1_identifier} (#{column_name});
          CREATE INDEX #{partition2_index} ON #{partition2_identifier} (#{column_name});

          CREATE INDEX #{index_name} ON #{table_name} (#{column_name});
        SQL
      end

      it 'drops the index on the parent table, cascading to all partitions', :aggregate_failures do
        expect_index_to_exist(partition1_index, schema: partition_schema)
        expect_index_to_exist(partition2_index, schema: partition_schema)
        expect_index_to_exist(index_name)

        expect(migration).to receive(:with_lock_retries).ordered.and_yield
        expect(migration).to receive(:remove_index).with(table_name, name: index_name).ordered.and_call_original

        migration.remove_concurrent_partitioned_index_by_name(table_name, index_name)

        expect_index_not_to_exist(partition1_index, schema: partition_schema)
        expect_index_not_to_exist(partition2_index, schema: partition_schema)
        expect_index_not_to_exist(index_name)
      end
    end

    context 'when the index does not exist' do
      it 'does not attempt to drop the index', :aggregate_failures do
        expect(migration).to receive(:index_name_exists?).with(table_name, index_name).and_return(false)

        expect(migration).not_to receive(:with_lock_retries)
        expect(migration).not_to receive(:remove_index)

        migration.remove_concurrent_partitioned_index_by_name(table_name, index_name)
      end
    end

    context 'when the given table is not a partitioned table' do
      before do
        allow(Gitlab::Database::PostgresPartitionedTable).to receive(:find_by_name_in_current_schema)
          .with(table_name).and_return(nil)
      end

      it 'raises an error', :aggregate_failures do
        expect(migration).not_to receive(:with_lock_retries)
        expect(migration).not_to receive(:remove_index)

        expect do
          migration.remove_concurrent_partitioned_index_by_name(table_name, index_name)
        end.to raise_error(ArgumentError, /#{table_name} is not a partitioned table/)
      end
    end
  end
end

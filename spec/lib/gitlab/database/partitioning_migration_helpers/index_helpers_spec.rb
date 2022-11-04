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
    allow(migration).to receive(:transaction_open?).and_return(false)

    connection.execute(<<~SQL)
      CREATE TABLE #{table_name} (
        id serial NOT NULL,
        created_at timestamptz NOT NULL,
        updated_at timestamptz NOT NULL,
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
        expect(migration).to receive(:add_index).with(table_name, column_name, { name: index_name }).ordered.and_call_original

        migration.add_concurrent_partitioned_index(table_name, column_name, name: index_name)

        expect_index_to_exist(partition1_index, schema: partition_schema)
        expect_index_to_exist(partition2_index, schema: partition_schema)
        expect_index_to_exist(index_name)
      end

      def expect_add_concurrent_index_and_call_original(table, column, index)
        expect(migration).to receive(:add_concurrent_index).ordered.with(table, column, { name: index, allow_partition: true })
          .and_wrap_original do |_, table, column, options|
            options.delete(:allow_partition)
            connection.add_index(table, column, **options)
          end
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
          .with(partition1_identifier, column_name, { name: partition1_index, where: 'x > 0', unique: true, allow_partition: true })

        expect(migration).to receive(:add_index)
          .with(table_name, column_name, { name: index_name, where: 'x > 0', unique: true })

        migration.add_concurrent_partitioned_index(table_name, column_name,
                                                   { name: index_name, where: 'x > 0', unique: true })
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

    context 'when run inside a transaction block' do
      it 'raises an error' do
        expect(migration).to receive(:transaction_open?).and_return(true)

        expect do
          migration.add_concurrent_partitioned_index(table_name, column_name)
        end.to raise_error(/can not be run inside a transaction/)
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

    context 'when run inside a transaction block' do
      it 'raises an error' do
        expect(migration).to receive(:transaction_open?).and_return(true)

        expect do
          migration.remove_concurrent_partitioned_index_by_name(table_name, index_name)
        end.to raise_error(/can not be run inside a transaction/)
      end
    end
  end

  describe '#find_duplicate_indexes' do
    context 'when duplicate and non-duplicate indexes exist' do
      let(:nonduplicate_column_name) { 'updated_at' }
      let(:nonduplicate_index_name) { 'updated_at_idx' }
      let(:duplicate_column_name) { 'created_at' }
      let(:duplicate_index_name1) { 'created_at_idx' }
      let(:duplicate_index_name2) { 'index_on_created_at' }

      before do
        connection.execute(<<~SQL)
          CREATE INDEX #{nonduplicate_index_name} ON #{table_name} (#{nonduplicate_column_name});
          CREATE INDEX #{duplicate_index_name1} ON #{table_name} (#{duplicate_column_name});
          CREATE INDEX #{duplicate_index_name2} ON #{table_name} (#{duplicate_column_name});
        SQL
      end

      subject do
        migration.find_duplicate_indexes(table_name)
      end

      it 'finds the duplicate index' do
        expect(subject).to match_array([match_array([duplicate_index_name1, duplicate_index_name2])])
      end
    end
  end

  describe '#indexes_by_definition_for_table' do
    context 'when a partitioned table has indexes' do
      subject do
        migration.indexes_by_definition_for_table(table_name)
      end

      before do
        connection.execute(<<~SQL)
          CREATE INDEX #{index_name} ON #{table_name} (#{column_name});
        SQL
      end

      it 'captures partitioned index names by index definition' do
        expect(subject).to match(a_hash_including({ "CREATE _ btree (#{column_name})" => index_name }))
      end
    end

    context 'when a non-partitioned table has indexes' do
      let(:regular_table_name) { '_test_regular_table' }
      let(:regular_index_name) { '_test_regular_index_name' }

      subject do
        migration.indexes_by_definition_for_table(regular_table_name)
      end

      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{regular_table_name} (
            #{column_name} timestamptz NOT NULL
          );

          CREATE INDEX #{regular_index_name} ON #{regular_table_name} (#{column_name});
        SQL
      end

      it 'captures index names by index definition' do
        expect(subject).to match(a_hash_including({ "CREATE _ btree (#{column_name})" => regular_index_name }))
      end
    end

    context 'when a non-partitioned table has duplicate indexes' do
      let(:regular_table_name) { '_test_regular_table' }
      let(:regular_index_name) { '_test_regular_index_name' }
      let(:duplicate_index_name) { '_test_duplicate_index_name' }

      subject do
        migration.indexes_by_definition_for_table(regular_table_name)
      end

      before do
        connection.execute(<<~SQL)
          CREATE TABLE #{regular_table_name} (
            #{column_name} timestamptz NOT NULL
          );

          CREATE INDEX #{regular_index_name} ON #{regular_table_name} (#{column_name});
          CREATE INDEX #{duplicate_index_name} ON #{regular_table_name} (#{column_name});
        SQL
      end

      it 'raises an error' do
        expect { subject }.to raise_error { described_class::DuplicatedIndexesError }
      end
    end
  end

  describe '#rename_indexes_for_table' do
    let(:original_table_name) { '_test_rename_indexes_table' }
    let(:first_partition_name) { '_test_rename_indexes_table_1' }
    let(:transient_table_name) { '_test_rename_indexes_table_child' }
    let(:custom_column_name) { 'created_at' }
    let(:generated_column_name) { 'updated_at' }
    let(:custom_index_name) { 'index_test_rename_indexes_table_on_created_at' }
    let(:custom_index_name_regenerated) { '_test_rename_indexes_table_created_at_idx' }
    let(:generated_index_name) { '_test_rename_indexes_table_updated_at_idx' }
    let(:generated_index_name_collided) { '_test_rename_indexes_table_updated_at_idx1' }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{original_table_name} (
          #{custom_column_name} timestamptz NOT NULL,
          #{generated_column_name} timestamptz NOT NULL
        );

        CREATE INDEX #{custom_index_name} ON #{original_table_name} (#{custom_column_name});
        CREATE INDEX ON #{original_table_name} (#{generated_column_name});
      SQL
    end

    context 'when changing a table within the current schema' do
      let!(:identifiers) { migration.indexes_by_definition_for_table(original_table_name) }

      before do
        connection.execute(<<~SQL)
          ALTER TABLE #{original_table_name} RENAME TO #{first_partition_name};
          CREATE TABLE #{original_table_name} (LIKE #{first_partition_name} INCLUDING ALL);
          DROP TABLE #{first_partition_name};
        SQL
      end

      it 'maps index names after they are changed' do
        migration.rename_indexes_for_table(original_table_name, identifiers)

        expect_index_to_exist(custom_index_name)
        expect_index_to_exist(generated_index_name)
      end

      it 'does not rename an index which does not exist in the to_hash' do
        partial_identifiers = identifiers.reject { |_, name| name == custom_index_name }

        migration.rename_indexes_for_table(original_table_name, partial_identifiers)

        expect_index_not_to_exist(custom_index_name)
        expect_index_to_exist(generated_index_name)
      end
    end

    context 'when partitioning an existing table' do
      before do
        connection.execute(<<~SQL)
          /* Create new parent table */
          CREATE TABLE #{first_partition_name} (LIKE #{original_table_name} INCLUDING ALL);
        SQL
      end

      it 'renames indexes across schemas' do
        # Capture index names generated by postgres
        generated_index_names = migration.indexes_by_definition_for_table(first_partition_name)

        # Capture index names from original table
        original_index_names = migration.indexes_by_definition_for_table(original_table_name)

        connection.execute(<<~SQL)
          /* Rename original table out of the way */
          ALTER TABLE #{original_table_name} RENAME TO #{transient_table_name};

          /* Rename new parent table to original name */
          ALTER TABLE #{first_partition_name} RENAME TO #{original_table_name};

          /* Move original table to gitlab_partitions_dynamic schema */
          ALTER TABLE #{transient_table_name} SET SCHEMA #{partition_schema};

          /* Rename original table to be the first partition */
          ALTER TABLE #{partition_schema}.#{transient_table_name} RENAME TO #{first_partition_name};
        SQL

        # Apply index names generated by postgres to first partition
        migration.rename_indexes_for_table(first_partition_name, generated_index_names, schema_name: partition_schema)

        expect_index_to_exist('_test_rename_indexes_table_1_created_at_idx')
        expect_index_to_exist('_test_rename_indexes_table_1_updated_at_idx')

        # Apply index names from original table to new parent table
        migration.rename_indexes_for_table(original_table_name, original_index_names)

        expect_index_to_exist(custom_index_name)
        expect_index_to_exist(generated_index_name)
      end
    end
  end
end

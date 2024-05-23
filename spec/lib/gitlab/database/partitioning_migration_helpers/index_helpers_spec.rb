# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PartitioningMigrationHelpers::IndexHelpers, feature_category: :database do
  include Database::TableSchemaHelpers

  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let(:table_name) { '_test_partitioned_table' }
  let(:column_name) { 'created_at' }
  let(:second_column_name) { 'updated_at' }
  let(:index_name) { '_test_partitioning_index_name' }
  let(:index_model) { Gitlab::Database::AsyncIndexes::PostgresAsyncIndex }
  let(:async_index_name1) { 'index_4a5e03c187' }
  let(:async_index_name2) { 'index_acc0d9e04e' }
  let(:second_index_name) { '_test_second_partitioning_index_name' }
  let(:partition_schema) { 'gitlab_partitions_dynamic' }
  let(:partition1_identifier) { "#{partition_schema}.#{table_name}_202001" }
  let(:partition2_identifier) { "#{partition_schema}.#{table_name}_202002" }
  let(:partition1_index) { "index_#{table_name}_202001_#{column_name}" }
  let(:partition2_index) { "index_#{table_name}_202002_#{column_name}" }
  let(:second_partition1_index) { "index_#{table_name}_202001_#{second_column_name}" }
  let(:second_partition2_index) { "index_#{table_name}_202002_#{second_column_name}" }

  before do
    allow(migration).to receive(:puts)
    allow(migration).to receive(:transaction_open?).and_return(false)

    connection.execute(<<~SQL)
      DROP TABLE IF EXISTS #{table_name};
      CREATE TABLE #{table_name} (
        id serial NOT NULL,
        created_at timestamptz NOT NULL,
        updated_at timestamptz NOT NULL,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);

      DROP TABLE IF EXISTS #{partition1_identifier};
      CREATE TABLE #{partition1_identifier} PARTITION OF #{table_name}
      FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

      DROP TABLE IF EXISTS #{partition2_identifier};
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

        migration.add_concurrent_partitioned_index(
          table_name,
          column_name,
          { name: index_name, where: 'x > 0', unique: true }
        )
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

    context 'when changing a table within the current schema' do # rubocop:disable RSpec/MultipleMemoizedHelpers -- new rubocop
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

  shared_examples 'raising undefined object error' do
    specify do
      expect { execute }.to raise_error(
        ArgumentError,
        /Could not find index for _test_partitioned_table/
      )
    end
  end

  describe '#rename_partitioned_index' do
    subject(:execute) { migration.rename_partitioned_index(table_name, old_index_name, new_index_name) }

    let(:old_index_name) { index_name }
    let(:new_index_name) { :_test_partitioning_index_name_new }

    before do
      allow(migration.connection).to receive(:transaction_open?).and_return(false)
    end

    context 'when old index exists' do
      before do
        create_old_partitioned_index
      end

      context 'when new index does not exists' do
        it 'renames the old index into the new name' do
          expect { execute }
            .to change { index_by_name(table_name, old_index_name) }.from(be_present).to(nil)
            .and change { index_by_name(partition1_identifier, old_index_name, partitioned_table: table_name) }
            .from(be_present).to(nil)
            .and change { index_by_name(partition2_identifier, old_index_name, partitioned_table: table_name) }
            .from(be_present).to(nil)
            .and change { index_by_name(table_name, new_index_name) }.from(nil).to(be_present)
            .and change { index_by_name(partition1_identifier, new_index_name, partitioned_table: table_name) }
            .from(nil).to(be_present)
            .and change { index_by_name(partition2_identifier, new_index_name, partitioned_table: table_name) }
            .from(nil).to(be_present)
        end
      end

      context 'when new index exists' do
        before do
          create_new_partitioned_index
        end

        it 'raises duplicate table error' do
          expect { execute }.to raise_error(
            ActiveRecord::StatementInvalid,
            /PG::DuplicateTable: ERROR: .*"#{new_index_name}".* exists/
          )
        end
      end
    end

    context 'when old index does not exist' do
      context 'when new index does not exists' do
        it_behaves_like 'raising undefined object error'
      end

      context 'when new index exists' do
        before do
          connection.execute(<<~SQL)
            CREATE INDEX #{second_partition1_index} ON #{partition1_identifier} (#{second_column_name});
            CREATE INDEX #{second_partition2_index} ON #{partition2_identifier} (#{second_column_name});

            CREATE INDEX #{new_index_name} ON #{table_name} (#{second_column_name});
          SQL
        end

        it_behaves_like 'raising undefined object error'
      end
    end
  end

  describe '#swap_partitioned_indexes' do
    subject(:execute) { migration.swap_partitioned_indexes(table_name, old_index_name, new_index_name) }

    let(:old_index_name) { index_name }
    let(:new_index_name) { :_test_partitioning_index_name_new }

    before do
      allow(migration.connection).to receive(:transaction_open?).and_return(false)
    end

    context 'when old index exists' do
      before do
        create_old_partitioned_index
      end

      context 'when new index does not exists' do
        it_behaves_like 'raising undefined object error'
      end

      context 'when new index exists' do
        before do
          create_new_partitioned_index
        end

        it 'swaps indexs' do
          expect { execute }
            .to change { index_by_name(table_name, old_index_name).columns }
            .from(match_array(column_name)).to(match_array(second_column_name))
            .and change { index_by_name(partition1_identifier, old_index_name, partitioned_table: table_name).columns }
            .from(match_array(column_name)).to(match_array(second_column_name))
            .and change { index_by_name(partition2_identifier, old_index_name, partitioned_table: table_name).columns }
            .from(match_array(column_name)).to(match_array(second_column_name))
            .and change { index_by_name(table_name, new_index_name).columns }
            .from(match_array(second_column_name)).to(match_array(column_name))
            .and change { index_by_name(partition1_identifier, new_index_name, partitioned_table: table_name).columns }
            .from(match_array(second_column_name)).to(match_array(column_name))
            .and change { index_by_name(partition2_identifier, new_index_name, partitioned_table: table_name).columns }
            .from(match_array(second_column_name)).to(match_array(column_name))
        end
      end
    end

    context 'when old index does not exist' do
      context 'when new index does not exists' do
        it_behaves_like 'raising undefined object error'
      end

      context 'when new index exists' do
        before do
          connection.execute(<<~SQL)
            CREATE INDEX #{second_partition1_index} ON #{partition1_identifier} (#{second_column_name});
            CREATE INDEX #{second_partition2_index} ON #{partition2_identifier} (#{second_column_name});

            CREATE INDEX #{new_index_name} ON #{table_name} (#{second_column_name});
          SQL
        end

        it_behaves_like 'raising undefined object error'
      end
    end
  end

  describe '#prepare_partitioned_async_index' do
    it 'creates the records for async index' do
      expect do
        migration.prepare_partitioned_async_index(table_name, 'id')
      end.to change { index_model.count }.by(2)

      async_index1 = index_model.find_by(table_name: partition1_identifier)

      expect(async_index1.name).to eq(async_index_name1)
      expect(async_index1.definition).to eq(%[CREATE INDEX CONCURRENTLY "#{async_index_name1}" ON #{migration.quote_table_name(partition1_identifier)} ("id")])

      async_index2 = index_model.find_by(table_name: partition2_identifier)

      expect(async_index2.name).to eq(async_index_name2)
      expect(async_index2.definition).to eq(%[CREATE INDEX CONCURRENTLY "#{async_index_name2}" ON #{migration.quote_table_name(partition2_identifier)} ("id")])
    end

    context 'when an explicit name is given' do
      let(:index_name) { 'my_async_index_name' }
      let(:async_index_name1) { 'index_6857af8dd5' }
      let(:async_index_name2) { 'index_eef161829a' }

      it 'creates the records with different partition index names' do
        expect do
          migration.prepare_partitioned_async_index(table_name, 'id', name: index_name)
        end.to change { index_model.count }.by(2)

        async_index1 = index_model.find_by(table_name: partition1_identifier)

        expect(async_index1.name).to eq(async_index_name1)
        expect(async_index1.definition).to eq(%[CREATE INDEX CONCURRENTLY "#{async_index_name1}" ON #{migration.quote_table_name(partition1_identifier)} ("id")])

        async_index2 = index_model.find_by(table_name: partition2_identifier)

        expect(async_index2.name).to eq(async_index_name2)
        expect(async_index2.definition).to eq(%[CREATE INDEX CONCURRENTLY "#{async_index_name2}" ON #{migration.quote_table_name(partition2_identifier)} ("id")])
      end
    end

    context 'when the partitioned index already exists' do
      it 'does not create the records' do
        connection.add_index(table_name, 'id', name: index_name)

        expect do
          migration.prepare_partitioned_async_index(table_name, 'id')
        end.not_to change { index_model.count }
      end
    end

    context 'when the partition index 1 already exists' do
      it 'does not create the record for partition 1' do
        connection.add_index(partition1_identifier, 'id', name: async_index_name1)

        expect do
          migration.prepare_partitioned_async_index(table_name, 'id')
        end.to change { index_model.count }.by(1)

        async_index2 = index_model.find_by(table_name: partition2_identifier)

        expect(async_index2.name).to eq(async_index_name2)
        expect(async_index2.definition).to eq(%[CREATE INDEX CONCURRENTLY "#{async_index_name2}" ON #{migration.quote_table_name(partition2_identifier)} ("id")])
      end
    end

    context 'when the records already exist' do
      it 'does not create the records' do
        create(:postgres_async_index, table_name: partition1_identifier, name: async_index_name1)
        create(:postgres_async_index, table_name: partition2_identifier, name: async_index_name2)

        expect do
          migration.prepare_partitioned_async_index(table_name, 'id')
        end.not_to change { index_model.count }
      end

      it 'updates definition if changed' do
        partition_index1 = create(:postgres_async_index, table_name: partition1_identifier, name: async_index_name1, definition: '...')
        partition_index2 = create(:postgres_async_index, table_name: partition2_identifier, name: async_index_name2, definition: '...')

        expect do
          migration.prepare_partitioned_async_index(table_name, 'id')
        end.to change { partition_index1.reload.definition }
        .and change { partition_index2.reload.definition }
      end

      it 'does not update definition if not changed' do
        index_definition1 = %[CREATE INDEX CONCURRENTLY "#{async_index_name1}" ON #{migration.quote_table_name(partition1_identifier)} ("id")]
        index_definition2 = %[CREATE INDEX CONCURRENTLY "#{async_index_name2}" ON #{migration.quote_table_name(partition2_identifier)} ("id")]
        partition_index1 = create(:postgres_async_index, table_name: partition1_identifier, name: async_index_name1, definition: index_definition1)
        partition_index2 = create(:postgres_async_index, table_name: partition2_identifier, name: async_index_name2, definition: index_definition2)

        expect do
          migration.prepare_partitioned_async_index(table_name, 'id')
        end.to not_change { partition_index1.reload.updated_at }
        .and not_change { partition_index2.reload.updated_at }
      end
    end

    context 'when the async index table does not exist' do
      it 'does not raise an error' do
        connection.drop_table(:postgres_async_indexes)

        expect(index_model).not_to receive(:safe_find_or_create_by!)

        expect { migration.prepare_partitioned_async_index(table_name, 'id') }.not_to raise_error
      end
    end

    context 'when the target table does not exist' do
      it 'raises an error' do
        expect { migration.prepare_partitioned_async_index(:non_existent_table, 'id') }.to(
          raise_error("non_existent_table is not a partitioned table")
        )
      end
    end
  end

  describe '#unprepare_partitioned_async_index' do
    let!(:async_index1) { create(:postgres_async_index, name: async_index_name1) }
    let!(:async_index2) { create(:postgres_async_index, name: async_index_name2) }

    it 'destroys the records' do
      expect do
        migration.unprepare_partitioned_async_index(table_name, 'id')
      end.to change { index_model.count }.by(-2)
    end

    context 'when an explicit name is given' do
      let(:index_name) { 'my_async_index_name' }
      let(:async_index_name1) { 'index_6857af8dd5' }
      let(:async_index_name2) { 'index_eef161829a' }

      it 'destroys the records' do
        expect do
          migration.unprepare_partitioned_async_index(table_name, 'id', name: index_name)
        end.to change { index_model.count }.by(-2)
      end
    end
  end

  describe '#unprepare_partitioned_async_index_by_name' do
    let(:index_name) { connection.index_name(table_name, 'id') }
    let!(:async_index1) { create(:postgres_async_index, name: async_index_name1) }
    let!(:async_index2) { create(:postgres_async_index, name: async_index_name2) }

    it 'destroys the records' do
      expect do
        migration.unprepare_partitioned_async_index_by_name(table_name, index_name)
      end.to change { index_model.count }.by(-2)
    end

    context 'when index name is blank' do
      let(:index_name) { nil }

      it 'raises argument error' do
        expect { migration.unprepare_partitioned_async_index_by_name(table_name, index_name) }
          .to raise_error(ArgumentError, 'Partitioned index name is required')
      end
    end
  end

  def create_old_partitioned_index
    connection.execute(<<~SQL)
      CREATE INDEX #{partition1_index} ON #{partition1_identifier} (#{column_name});
      CREATE INDEX #{partition2_index} ON #{partition2_identifier} (#{column_name});

      CREATE INDEX #{old_index_name} ON #{table_name} (#{column_name});
    SQL
  end

  def create_new_partitioned_index
    connection.execute(<<~SQL)
      CREATE INDEX #{second_partition1_index} ON #{partition1_identifier} (#{second_column_name});
      CREATE INDEX #{second_partition2_index} ON #{partition2_identifier} (#{second_column_name});

      CREATE INDEX #{new_index_name} ON #{table_name} (#{second_column_name});
    SQL
  end
end

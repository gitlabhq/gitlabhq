# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers do
  include Database::TableSchemaHelpers

  let(:migration) do
    ActiveRecord::Migration.new.extend(Gitlab::Database::PartitioningMigrationHelpers)
  end

  let(:source_table_name) { '_test_partitioned_table' }
  let(:target_table_name) { '_test_referenced_table' }
  let(:column_name) { "#{target_table_name}_id" }
  let(:foreign_key_name) { '_test_partitioned_fk' }
  let(:partition_schema) { 'gitlab_partitions_dynamic' }
  let(:partition1_name) { "#{partition_schema}.#{source_table_name}_202001" }
  let(:partition2_name) { "#{partition_schema}.#{source_table_name}_202002" }
  let(:options) do
    {
      column: column_name,
      name: foreign_key_name,
      on_delete: :cascade,
      validate: true
    }
  end

  before do
    allow(migration).to receive(:puts)

    connection.execute(<<~SQL)
      CREATE TABLE #{target_table_name} (
        id serial NOT NULL,
        PRIMARY KEY (id)
      );

      CREATE TABLE #{source_table_name} (
        id serial NOT NULL,
        #{column_name} int NOT NULL,
        created_at timestamptz NOT NULL,
        PRIMARY KEY (id, created_at)
      ) PARTITION BY RANGE (created_at);

      CREATE TABLE #{partition1_name} PARTITION OF #{source_table_name}
      FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

      CREATE TABLE #{partition2_name} PARTITION OF #{source_table_name}
      FOR VALUES FROM ('2020-02-01') TO ('2020-03-01');
    SQL
  end

  describe '#add_concurrent_partitioned_foreign_key' do
    before do
      allow(migration).to receive(:foreign_key_exists?)
        .with(source_table_name, target_table_name, anything)
        .and_return(false)

      allow(migration).to receive(:with_lock_retries).and_yield
    end

    context 'when the foreign key does not exist on the parent table' do
      it 'creates the foreign key on each partition, and the parent table' do
        expect(migration).to receive(:foreign_key_exists?)
          .with(source_table_name, target_table_name, **options)
          .and_return(false)

        expect(migration).to receive(:concurrent_partitioned_foreign_key_name).and_return(foreign_key_name)

        expect_add_concurrent_fk_and_call_original(partition1_name, target_table_name, **options)
        expect_add_concurrent_fk_and_call_original(partition2_name, target_table_name, **options)

        expect(migration).to receive(:with_lock_retries).ordered.and_yield
        expect(migration).to receive(:add_foreign_key)
          .with(source_table_name, target_table_name, **options)
          .ordered
          .and_call_original

        migration.add_concurrent_partitioned_foreign_key(source_table_name, target_table_name, column: column_name)

        expect_foreign_key_to_exist(source_table_name, foreign_key_name)
      end

      def expect_add_concurrent_fk_and_call_original(source_table_name, target_table_name, options)
        expect(migration).to receive(:add_concurrent_foreign_key)
          .ordered
          .with(source_table_name, target_table_name, options)
          .and_wrap_original do |_, source_table_name, target_table_name, options|
            connection.add_foreign_key(source_table_name, target_table_name, **options)
          end
      end
    end

    context 'when the foreign key exists on the parent table' do
      it 'does not attempt to create any foreign keys' do
        expect(migration).to receive(:concurrent_partitioned_foreign_key_name).and_return(foreign_key_name)

        expect(migration).to receive(:foreign_key_exists?)
          .with(source_table_name, target_table_name, **options)
          .and_return(true)

        expect(migration).not_to receive(:add_concurrent_foreign_key)
        expect(migration).not_to receive(:with_lock_retries)
        expect(migration).not_to receive(:add_foreign_key)

        migration.add_concurrent_partitioned_foreign_key(source_table_name, target_table_name, column: column_name)

        expect_foreign_key_not_to_exist(source_table_name, foreign_key_name)
      end
    end

    context 'when additional foreign key options are given' do
      let(:options) do
        {
          column: column_name,
          name: '_my_fk_name',
          on_delete: :restrict,
          validate: true
        }
      end

      it 'forwards them to the foreign key helper methods' do
        expect(migration).to receive(:foreign_key_exists?)
          .with(source_table_name, target_table_name, **options)
          .and_return(false)

        expect(migration).not_to receive(:concurrent_partitioned_foreign_key_name)

        expect_add_concurrent_fk(partition1_name, target_table_name, **options)
        expect_add_concurrent_fk(partition2_name, target_table_name, **options)

        expect(migration).to receive(:with_lock_retries).ordered.and_yield
        expect(migration).to receive(:add_foreign_key).with(source_table_name, target_table_name, **options).ordered

        migration.add_concurrent_partitioned_foreign_key(source_table_name, target_table_name,
          column: column_name, name: '_my_fk_name', on_delete: :restrict)
      end

      def expect_add_concurrent_fk(source_table_name, target_table_name, options)
        expect(migration).to receive(:add_concurrent_foreign_key)
          .ordered
          .with(source_table_name, target_table_name, options)
      end
    end
  end
end

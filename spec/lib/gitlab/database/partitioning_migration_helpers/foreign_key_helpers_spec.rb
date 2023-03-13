# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers, feature_category: :database do
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
  let(:validate) { true }
  let(:options) do
    {
      column: column_name,
      name: foreign_key_name,
      on_delete: :cascade,
      on_update: nil,
      primary_key: :id
    }
  end

  let(:create_options) do
    options
      .except(:primary_key)
      .merge!(reverse_lock_order: false, target_column: :id, validate: validate)
  end

  before do
    allow(migration).to receive(:puts)
    allow(migration).to receive(:transaction_open?).and_return(false)

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

        expect_add_concurrent_fk_and_call_original(partition1_name, target_table_name, **create_options)
        expect_add_concurrent_fk_and_call_original(partition2_name, target_table_name, **create_options)

        expect(migration).to receive(:add_concurrent_foreign_key)
          .with(source_table_name, target_table_name, allow_partitioned: true, **create_options)
          .ordered
          .and_call_original

        migration.add_concurrent_partitioned_foreign_key(source_table_name, target_table_name, column: column_name)

        expect_foreign_key_to_exist(source_table_name, foreign_key_name)
      end

      context 'with validate: false option' do
        let(:validate) { false }
        let(:options) do
          {
            column: column_name,
            name: foreign_key_name,
            on_delete: :cascade,
            on_update: nil,
            primary_key: :id
          }
        end

        it 'creates the foreign key only on partitions' do
          expect(migration).to receive(:foreign_key_exists?)
            .with(source_table_name, target_table_name, **options)
            .and_return(false)

          expect(migration).to receive(:concurrent_partitioned_foreign_key_name).and_return(foreign_key_name)

          expect_add_concurrent_fk_and_call_original(partition1_name, target_table_name, **create_options)
          expect_add_concurrent_fk_and_call_original(partition2_name, target_table_name, **create_options)

          expect(migration).not_to receive(:add_concurrent_foreign_key)
            .with(source_table_name, target_table_name, **create_options)

          migration.add_concurrent_partitioned_foreign_key(
            source_table_name, target_table_name,
            column: column_name, validate: false)

          expect_foreign_key_not_to_exist(source_table_name, foreign_key_name)
        end
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

        migration.add_concurrent_partitioned_foreign_key(source_table_name, target_table_name, column: column_name)

        expect_foreign_key_not_to_exist(source_table_name, foreign_key_name)
      end
    end

    context 'when additional foreign key options are given' do
      let(:exits_options) do
        {
          column: column_name,
          name: '_my_fk_name',
          on_delete: :restrict,
          on_update: nil,
          primary_key: :id
        }
      end

      let(:create_options) do
        exits_options
          .except(:primary_key)
          .merge!(reverse_lock_order: false, target_column: :id, validate: true)
      end

      it 'forwards them to the foreign key helper methods' do
        expect(migration).to receive(:foreign_key_exists?)
          .with(source_table_name, target_table_name, **exits_options)
          .and_return(false)

        expect(migration).not_to receive(:concurrent_partitioned_foreign_key_name)

        expect_add_concurrent_fk(partition1_name, target_table_name, **create_options)
        expect_add_concurrent_fk(partition2_name, target_table_name, **create_options)

        expect(migration).to receive(:add_concurrent_foreign_key)
          .with(source_table_name, target_table_name, allow_partitioned: true, **create_options)
          .ordered

        migration.add_concurrent_partitioned_foreign_key(
          source_table_name,
          target_table_name,
          column: column_name,
          name: '_my_fk_name',
          on_delete: :restrict
        )
      end

      def expect_add_concurrent_fk(source_table_name, target_table_name, options)
        expect(migration).to receive(:add_concurrent_foreign_key)
          .ordered
          .with(source_table_name, target_table_name, options)
      end
    end

    context 'when run inside a transaction block' do
      it 'raises an error' do
        expect(migration).to receive(:transaction_open?).and_return(true)

        expect do
          migration.add_concurrent_partitioned_foreign_key(source_table_name, target_table_name, column: column_name)
        end.to raise_error(/can not be run inside a transaction/)
      end
    end
  end

  describe '#validate_partitioned_foreign_key' do
    context 'when run inside a transaction block' do
      it 'raises an error' do
        expect(migration).to receive(:transaction_open?).and_return(true)

        expect do
          migration.validate_partitioned_foreign_key(source_table_name, column_name, name: '_my_fk_name')
        end.to raise_error(/can not be run inside a transaction/)
      end
    end

    context 'when run outside a transaction block' do
      before do
        migration.add_concurrent_partitioned_foreign_key(
          source_table_name,
          target_table_name,
          column: column_name,
          name: foreign_key_name,
          validate: false
        )
      end

      it 'validates FK for each partition' do
        expect(migration).to receive(:execute).with(/SET statement_timeout TO 0/).twice
        expect(migration).to receive(:execute).with(/RESET statement_timeout/).twice
        expect(migration).to receive(:execute)
          .with(/ALTER TABLE #{partition1_name} VALIDATE CONSTRAINT #{foreign_key_name}/).ordered
        expect(migration).to receive(:execute)
          .with(/ALTER TABLE #{partition2_name} VALIDATE CONSTRAINT #{foreign_key_name}/).ordered

        migration.validate_partitioned_foreign_key(source_table_name, column_name, name: foreign_key_name)
      end
    end
  end
end

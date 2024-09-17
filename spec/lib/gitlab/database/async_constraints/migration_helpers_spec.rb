# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncConstraints::MigrationHelpers, feature_category: :database do
  let(:migration) { Gitlab::Database::Migration[2.1].new }
  let(:connection) { ApplicationRecord.connection }
  let(:constraint_model) { Gitlab::Database::AsyncConstraints::PostgresAsyncConstraintValidation }
  let(:table_name) { '_test_async_fks' }
  let(:column_name) { 'parent_id' }
  let(:fk_name) { nil }

  context 'with async FK validation on regular tables' do
    before do
      allow(migration).to receive(:puts)
      allow(migration.connection).to receive(:transaction_open?).and_return(false)

      connection.create_table(table_name) do |t|
        t.integer column_name
      end

      migration.add_concurrent_foreign_key(
        table_name, table_name,
        column: column_name, validate: false, name: fk_name)
    end

    describe '#prepare_async_foreign_key_validation' do
      it 'creates the record for the async FK validation' do
        expect do
          migration.prepare_async_foreign_key_validation(table_name, column_name)
        end.to change { constraint_model.where(table_name: table_name).count }.by(1)

        record = constraint_model.find_by(table_name: table_name)

        expect(record.name).to start_with('fk_')
        expect(record).to be_foreign_key
      end

      context 'when an explicit name is given' do
        let(:fk_name) { 'my_fk_name' }

        it 'creates the record with the given name' do
          expect do
            migration.prepare_async_foreign_key_validation(table_name, name: fk_name)
          end.to change { constraint_model.where(name: fk_name).count }.by(1)

          record = constraint_model.find_by(name: fk_name)

          expect(record.table_name).to eq(table_name)
          expect(record).to be_foreign_key
        end
      end

      context 'when the FK does not exist' do
        it 'returns an error' do
          expect do
            migration.prepare_async_foreign_key_validation(table_name, name: 'no_fk')
          end.to raise_error RuntimeError, /Could not find foreign key "no_fk" on table "_test_async_fks"/
        end
      end

      context 'when the record already exists' do
        let(:fk_name) { 'my_fk_name' }

        it 'does attempt to create the record' do
          create(:postgres_async_constraint_validation, table_name: table_name, name: fk_name)

          expect do
            migration.prepare_async_foreign_key_validation(table_name, name: fk_name)
          end.not_to change { constraint_model.where(name: fk_name).count }
        end
      end

      context 'when the async FK validation table does not exist' do
        it 'does not raise an error' do
          connection.drop_table(constraint_model.table_name)

          expect(constraint_model).not_to receive(:safe_find_or_create_by!)

          expect { migration.prepare_async_foreign_key_validation(table_name, column_name) }.not_to raise_error
        end
      end
    end

    describe '#unprepare_async_foreign_key_validation' do
      context 'with foreign keys' do
        before do
          migration.prepare_async_foreign_key_validation(table_name, column_name, name: fk_name)
        end

        it 'destroys the record' do
          expect do
            migration.unprepare_async_foreign_key_validation(table_name, column_name)
          end.to change { constraint_model.where(table_name: table_name).count }.by(-1)
        end

        context 'when an explicit name is given' do
          let(:fk_name) { 'my_test_async_fk' }

          it 'destroys the record' do
            expect do
              migration.unprepare_async_foreign_key_validation(table_name, name: fk_name)
            end.to change { constraint_model.where(name: fk_name).count }.by(-1)
          end
        end

        context 'when the async fk validation table does not exist' do
          it 'does not raise an error' do
            connection.drop_table(constraint_model.table_name)

            expect(constraint_model).not_to receive(:find_by)

            expect { migration.unprepare_async_foreign_key_validation(table_name, column_name) }.not_to raise_error
          end
        end
      end

      context 'with other types of constraints' do
        let(:name) { 'my_test_async_constraint' }
        let(:constraint) { create(:postgres_async_constraint_validation, table_name: table_name, name: name) }

        it 'does not destroy the record' do
          constraint.update_column(:constraint_type, 99)

          expect do
            migration.unprepare_async_foreign_key_validation(table_name, name: name)
          end.not_to change { constraint_model.where(name: name).count }

          expect(constraint).to be_present
        end
      end
    end
  end

  context 'with async FK validation on partitioned tables' do
    let(:partition_schema) { 'gitlab_partitions_dynamic' }
    let(:partition1_name) { "#{partition_schema}.#{table_name}_202001" }
    let(:partition2_name) { "#{partition_schema}.#{table_name}_202002" }
    let(:fk_name) { 'my_partitioned_fk_name' }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (
          id serial NOT NULL,
          #{column_name} int NOT NULL,
          created_at timestamptz NOT NULL,
          PRIMARY KEY (id, created_at)
        ) PARTITION BY RANGE (created_at);

        CREATE TABLE #{partition1_name} PARTITION OF #{table_name}
        FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

        CREATE TABLE #{partition2_name} PARTITION OF #{table_name}
        FOR VALUES FROM ('2020-02-01') TO ('2020-03-01');
      SQL
    end

    describe '#prepare_partitioned_async_foreign_key_validation' do
      it 'delegates to prepare_async_foreign_key_validation for each partition' do
        expect(migration)
          .to receive(:prepare_async_foreign_key_validation)
          .with(partition1_name, column_name, name: fk_name)

        expect(migration)
          .to receive(:prepare_async_foreign_key_validation)
          .with(partition2_name, column_name, name: fk_name)

        migration.prepare_partitioned_async_foreign_key_validation(table_name, column_name, name: fk_name)
      end
    end

    describe '#unprepare_partitioned_async_foreign_key_validation' do
      it 'delegates to unprepare_async_foreign_key_validation for each partition' do
        expect(migration)
          .to receive(:unprepare_async_foreign_key_validation)
          .with(partition1_name, column_name, name: fk_name)

        expect(migration)
          .to receive(:unprepare_async_foreign_key_validation)
          .with(partition2_name, column_name, name: fk_name)

        migration.unprepare_partitioned_async_foreign_key_validation(table_name, column_name, name: fk_name)
      end
    end
  end

  context 'with async check constraint validations on regular tables' do
    let(:table_name) { '_test_async_check_constraints' }
    let(:check_name) { 'partitioning_constraint' }

    before do
      allow(migration).to receive(:puts)
      allow(migration.connection).to receive(:transaction_open?).and_return(false)

      connection.create_table(table_name) do |t|
        t.integer column_name
      end

      migration.add_check_constraint(
        table_name, "#{column_name} = 1",
        check_name, validate: false)
    end

    describe '#prepare_async_check_constraint_validation' do
      it 'creates the record for async validation' do
        expect do
          migration.prepare_async_check_constraint_validation(table_name, name: check_name)
        end.to change { constraint_model.where(name: check_name).count }.by(1)

        record = constraint_model.find_by(name: check_name)

        expect(record.table_name).to eq(table_name)
        expect(record).to be_check_constraint
      end

      context 'when the check constraint does not exist' do
        it 'returns an error' do
          expect do
            migration.prepare_async_check_constraint_validation(table_name, name: 'missing')
          end.to raise_error RuntimeError, /Could not find check constraint "missing" on table "#{table_name}"/
        end
      end

      context 'when the record already exists' do
        it 'does attempt to create the record' do
          create(:postgres_async_constraint_validation,
            table_name: table_name,
            name: check_name,
            constraint_type: :check_constraint)

          expect do
            migration.prepare_async_check_constraint_validation(table_name, name: check_name)
          end.not_to change { constraint_model.where(name: check_name).count }
        end
      end

      context 'when the async validation table does not exist' do
        it 'does not raise an error' do
          connection.drop_table(constraint_model.table_name)

          expect(constraint_model).not_to receive(:safe_find_or_create_by!)

          expect { migration.prepare_async_check_constraint_validation(table_name, name: check_name) }
            .not_to raise_error
        end
      end
    end

    describe '#unprepare_async_check_constraint_validation' do
      context 'with check constraints' do
        before do
          migration.prepare_async_check_constraint_validation(table_name, name: check_name)
        end

        it 'destroys the record' do
          expect do
            migration.unprepare_async_check_constraint_validation(table_name, name: check_name)
          end.to change { constraint_model.where(name: check_name).count }.by(-1)
        end

        context 'when the async validation table does not exist' do
          it 'does not raise an error' do
            connection.drop_table(constraint_model.table_name)

            expect(constraint_model).not_to receive(:find_by)

            expect { migration.unprepare_async_check_constraint_validation(table_name, name: check_name) }
              .not_to raise_error
          end
        end
      end

      context 'with other types of constraints' do
        let(:constraint) { create(:postgres_async_constraint_validation, table_name: table_name, name: check_name) }

        it 'does not destroy the record' do
          constraint.update_column(:constraint_type, 99)

          expect do
            migration.unprepare_async_check_constraint_validation(table_name, name: check_name)
          end.not_to change { constraint_model.where(name: check_name).count }

          expect(constraint).to be_present
        end
      end
    end
  end

  context 'with async check constraint validations on partitioned tables' do
    let(:partition_schema) { 'gitlab_partitions_dynamic' }
    let(:partition1_name) { "#{partition_schema}.#{table_name}_202001" }
    let(:partition2_name) { "#{partition_schema}.#{table_name}_202002" }
    let(:check_name) { 'partitioning_constraint' }

    before do
      allow(migration).to receive(:puts)
      allow(migration.connection).to receive(:transaction_open?).and_return(false)

      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (
          id serial NOT NULL,
          #{column_name} int NOT NULL,
          created_at timestamptz NOT NULL,
          PRIMARY KEY (id, created_at)
        ) PARTITION BY RANGE (created_at);

        CREATE TABLE #{partition1_name} PARTITION OF #{table_name}
        FOR VALUES FROM ('2020-01-01') TO ('2020-02-01');

        CREATE TABLE #{partition2_name} PARTITION OF #{table_name}
        FOR VALUES FROM ('2020-02-01') TO ('2020-03-01');
      SQL

      migration.add_check_constraint(
        partition1_name, "#{column_name} = 1",
        check_name, validate: false)

      migration.add_check_constraint(
        partition2_name, "#{column_name} = 1",
        check_name, validate: false)
    end

    describe '#prepare_partitioned_async_check_constraint_validation' do
      it 'delegates to prepare_async_check_constraint_validation for each partition' do
        expect(migration)
          .to receive(:prepare_async_check_constraint_validation)
          .with(partition1_name, name: check_name)

        expect(migration)
          .to receive(:prepare_async_check_constraint_validation)
          .with(partition2_name, name: check_name)

        migration.prepare_partitioned_async_check_constraint_validation(table_name, name: check_name)
      end
    end

    describe '#unprepare_partitioned_async_check_constraint_validation' do
      it 'delegates to unprepare_async_check_constraint_validation for each partition' do
        expect(migration)
          .to receive(:unprepare_async_check_constraint_validation)
          .with(partition1_name, name: check_name)

        expect(migration)
          .to receive(:unprepare_async_check_constraint_validation)
          .with(partition2_name, name: check_name)

        migration.unprepare_partitioned_async_check_constraint_validation(table_name, name: check_name)
      end
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes::MigrationHelpers, feature_category: :database do
  let(:migration) { ActiveRecord::Migration.new.extend(described_class) }
  let(:index_model) { Gitlab::Database::AsyncIndexes::PostgresAsyncIndex }
  let(:connection) { ApplicationRecord.connection }
  let(:table_name) { '_test_async_indexes' }
  let(:index_name) { "index_#{table_name}_on_id" }

  before do
    allow(migration).to receive(:puts)
  end

  describe '#unprepare_async_index' do
    let!(:async_index) { create(:postgres_async_index, name: index_name) }

    it 'destroys the record' do
      expect do
        migration.unprepare_async_index(table_name, 'id')
      end.to change { index_model.where(name: index_name).count }.by(-1)
    end

    context 'when an explicit name is given' do
      let(:index_name) { 'my_test_async_index' }

      it 'destroys the record' do
        expect do
          migration.unprepare_async_index(table_name, 'id', name: index_name)
        end.to change { index_model.where(name: index_name).count }.by(-1)
      end
    end

    context 'when the async index table does not exist' do
      it 'does not raise an error' do
        connection.drop_table(:postgres_async_indexes)

        expect(index_model).not_to receive(:find_by)

        expect { migration.unprepare_async_index(table_name, 'id') }.not_to raise_error
      end
    end
  end

  describe '#unprepare_async_index_by_name' do
    let(:index_name) { "index_#{table_name}_on_id" }
    let!(:async_index) { create(:postgres_async_index, name: index_name) }

    it 'destroys the record' do
      expect do
        migration.unprepare_async_index_by_name(table_name, index_name)
      end.to change { index_model.where(name: index_name).count }.by(-1)
    end

    context 'when the async index table does not exist' do
      it 'does not raise an error' do
        connection.drop_table(:postgres_async_indexes)

        expect(index_model).not_to receive(:find_by)

        expect { migration.unprepare_async_index_by_name(table_name, index_name) }.not_to raise_error
      end
    end
  end

  describe '#prepare_async_index' do
    before do
      connection.create_table(table_name)
    end

    it 'creates the record for the async index' do
      expect do
        migration.prepare_async_index(table_name, 'id')
      end.to change { index_model.where(name: index_name).count }.by(1)

      record = index_model.find_by(name: index_name)

      expect(record.table_name).to eq(table_name)
      expect(record.definition).to match(/CREATE INDEX CONCURRENTLY "#{index_name}"/)
    end

    context 'when an explicit name is given' do
      let(:index_name) { 'my_async_index_name' }

      it 'creates the record with the given name' do
        expect do
          migration.prepare_async_index(table_name, 'id', name: index_name)
        end.to change { index_model.where(name: index_name).count }.by(1)

        record = index_model.find_by(name: index_name)

        expect(record.table_name).to eq(table_name)
        expect(record.definition).to match(/CREATE INDEX CONCURRENTLY "#{index_name}"/)
      end
    end

    context 'when the index already exists' do
      it 'does not create the record' do
        connection.add_index(table_name, 'id', name: index_name)

        expect do
          migration.prepare_async_index(table_name, 'id')
        end.not_to change { index_model.where(name: index_name).count }
      end
    end

    context 'when the record already exists' do
      it 'does attempt to create the record' do
        create(:postgres_async_index, table_name: table_name, name: index_name)

        expect do
          migration.prepare_async_index(table_name, 'id')
        end.not_to change { index_model.where(name: index_name).count }
      end

      it 'updates definition if changed' do
        index = create(:postgres_async_index, table_name: table_name, name: index_name, definition: '...')

        expect do
          migration.prepare_async_index(table_name, 'id', name: index_name)
        end.to change { index.reload.definition }
      end

      it 'does not update definition if not changed' do
        definition = "CREATE INDEX CONCURRENTLY \"index_#{table_name}_on_id\" ON \"#{table_name}\" (\"id\")"
        index = create(:postgres_async_index, table_name: table_name, name: index_name, definition: definition)

        expect do
          migration.prepare_async_index(table_name, 'id', name: index_name)
        end.not_to change { index.reload.updated_at }
      end
    end

    context 'when the async index table does not exist' do
      it 'does not raise an error' do
        connection.drop_table(:postgres_async_indexes)

        expect(index_model).not_to receive(:safe_find_or_create_by!)

        expect { migration.prepare_async_index(table_name, 'id') }.not_to raise_error
      end
    end

    context 'when the target table does not exist' do
      it 'raises an error' do
        expect { migration.prepare_async_index(:non_existent_table, 'id') }.to(
          raise_error("Table non_existent_table does not exist")
        )
      end
    end

    context 'when the table is partitioned' do
      it 'raises an error' do
        expect { migration.prepare_async_index('p_ci_builds', 'id') }.to(
          raise_error(ArgumentError, "prepare_async_index can not be used on a partitioned table. " \
            "Please use prepare_partitioned_async_index on the partitioned table.")
        )
      end
    end
  end

  describe '#prepare_async_index_from_sql' do
    let(:index_definition) { "CREATE INDEX CONCURRENTLY #{index_name} ON #{table_name} USING btree(id)" }

    subject(:prepare_async_index_from_sql) do
      migration.prepare_async_index_from_sql(index_definition)
    end

    before do
      connection.create_table(table_name)

      allow(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to receive(:require_ddl_mode!).and_call_original
    end

    it 'requires ddl mode' do
      prepare_async_index_from_sql

      expect(Gitlab::Database::QueryAnalyzers::RestrictAllowedSchemas).to have_received(:require_ddl_mode!)
    end

    context 'when the given index is invalid' do
      let(:index_definition) { "SELECT FROM users" }

      it 'raises a RuntimeError' do
        expect { prepare_async_index_from_sql }.to raise_error(RuntimeError, 'Index statement not found!')
      end
    end

    context 'when the given index is valid' do
      context 'when the index algorithm is not concurrent' do
        let(:index_definition) { "CREATE INDEX #{index_name} ON #{table_name} USING btree(id)" }

        it 'raises a RuntimeError' do
          expect { prepare_async_index_from_sql }.to raise_error(RuntimeError, 'Index must be created concurrently!')
        end
      end

      context 'when the index algorithm is concurrent' do
        context 'when the statement tries to create an index for non-existing table' do
          let(:index_definition) { "CREATE INDEX CONCURRENTLY #{index_name} ON foo_table USING btree(id)" }

          it 'raises a RuntimeError' do
            expect { prepare_async_index_from_sql }.to raise_error(RuntimeError, 'Table does not exist!')
          end
        end

        context 'when the statement tries to create an index for an existing table' do
          context 'when the async index creation is not available' do
            before do
              connection.drop_table(:postgres_async_indexes)
            end

            it 'does not raise an error' do
              expect { prepare_async_index_from_sql }.not_to raise_error
            end
          end

          context 'when the async index creation is available' do
            context 'when there is already an index with the given name' do
              before do
                connection.add_index(table_name, 'id', name: index_name)
              end

              it 'does not create the async index record' do
                expect { prepare_async_index_from_sql }.not_to change { index_model.where(name: index_name).count }
              end
            end

            context 'when there is no index with the given name' do
              let(:async_index) { index_model.find_by(name: index_name) }

              it 'creates the async index record' do
                expect { prepare_async_index_from_sql }.to change { index_model.where(name: index_name).count }.by(1)
              end

              it 'sets the async index attributes correctly' do
                prepare_async_index_from_sql

                expect(async_index).to have_attributes(table_name: table_name, definition: index_definition)
              end
            end

            context 'when the given SQL has whitespace' do
              let(:index_definition) { "    #{super()}" }
              let(:async_index) { index_model.find_by(name: index_name) }

              it 'creates the async index record' do
                expect { prepare_async_index_from_sql }.to change { index_model.where(name: index_name).count }.by(1)
              end

              it 'sets the async index attributes correctly' do
                prepare_async_index_from_sql

                expect(async_index).to have_attributes(table_name: table_name, definition: index_definition.strip)
              end
            end
          end
        end
      end
    end
  end

  describe '#prepare_async_index_removal' do
    before do
      connection.create_table(table_name)
      connection.add_index(table_name, 'id', name: index_name)
    end

    it 'creates the record for the async index removal' do
      expect do
        migration.prepare_async_index_removal(table_name, 'id', name: index_name)
      end.to change { index_model.where(name: index_name).count }.by(1)

      record = index_model.find_by(name: index_name)

      expect(record.table_name).to eq(table_name)
      expect(record.definition).to match(/DROP INDEX CONCURRENTLY "#{index_name}"/)
    end

    context 'when the index does not exist' do
      it 'does not create the record' do
        connection.remove_index(table_name, 'id', name: index_name)

        expect do
          migration.prepare_async_index_removal(table_name, 'id', name: index_name)
        end.not_to change { index_model.where(name: index_name).count }
      end
    end

    context 'when the record already exists' do
      it 'does attempt to create the record' do
        create(:postgres_async_index, table_name: table_name, name: index_name)

        expect do
          migration.prepare_async_index_removal(table_name, 'id', name: index_name)
        end.not_to change { index_model.where(name: index_name).count }
      end
    end

    context 'when targeting a partitioned table' do
      let(:table_name) { '_test_partitioned_table' }
      let(:index_name) { '_test_partitioning_index_name' }
      let(:column_name) { 'created_at' }
      let(:partition_schema) { 'gitlab_partitions_dynamic' }
      let(:partition1_identifier) { "#{partition_schema}.#{table_name}_202001" }
      let(:partition2_identifier) { "#{partition_schema}.#{table_name}_202002" }

      before do
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

          CREATE INDEX #{index_name} ON #{table_name}(#{column_name});
        SQL
      end

      it 'creates the record for the async index removal' do
        expect do
          migration.prepare_async_index_removal(table_name, column_name, name: index_name)
        end.to change { index_model.where(name: index_name).count }.by(1)

        record = index_model.find_by(name: index_name)

        expect(record.table_name).to eq(table_name)
        expect(record.definition).to match(/DROP INDEX "#{index_name}"/)
      end
    end
  end
end

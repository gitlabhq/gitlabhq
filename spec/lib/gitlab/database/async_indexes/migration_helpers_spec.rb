# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncIndexes::MigrationHelpers do
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

    context 'when the flag is enabled' do
      before do
        stub_feature_flags(database_async_index_creation: true)
      end

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

    context 'when the feature flag is disabled' do
      it 'does not destroy the record' do
        stub_feature_flags(database_async_index_creation: false)

        expect do
          migration.unprepare_async_index(table_name, 'id')
        end.not_to change { index_model.where(name: index_name).count }
      end
    end
  end

  describe '#unprepare_async_index_by_name' do
    let(:index_name) { "index_#{table_name}_on_id" }
    let!(:async_index) { create(:postgres_async_index, name: index_name) }

    context 'when the flag is enabled' do
      before do
        stub_feature_flags(database_async_index_creation: true)
      end

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

    context 'when the feature flag is disabled' do
      it 'does not destroy the record' do
        stub_feature_flags(database_async_index_creation: false)

        expect do
          migration.unprepare_async_index_by_name(table_name, index_name)
        end.not_to change { index_model.where(name: index_name).count }
      end
    end
  end

  describe '#prepare_async_index' do
    before do
      connection.create_table(table_name)
    end

    context 'when the feature flag is enabled' do
      before do
        stub_feature_flags(database_async_index_creation: true)
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
      end

      context 'when the async index table does not exist' do
        it 'does not raise an error' do
          connection.drop_table(:postgres_async_indexes)

          expect(index_model).not_to receive(:safe_find_or_create_by!)

          expect { migration.prepare_async_index(table_name, 'id') }.not_to raise_error
        end
      end
    end

    context 'when the feature flag is disabled' do
      it 'does not create the record' do
        stub_feature_flags(database_async_index_creation: false)

        expect do
          migration.prepare_async_index(table_name, 'id')
        end.not_to change { index_model.where(name: index_name).count }
      end
    end
  end
end

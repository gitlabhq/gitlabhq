# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers, feature_category: :database do
  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let(:connection) { ActiveRecord::Base.connection }
  let(:table_not_partitioned) { '_test_not_partitioned_table' }
  let(:table_partitioned) { '_test_partitioned_table' }

  before do
    connection.execute(<<~SQL)
      CREATE TABLE _test_partitioned_table
      (
        id serial NOT NULL,
        PARTITION bigint  NULL DEFAULT 1,
        PRIMARY KEY (id, partition)
      ) PARTITION BY list(partition);

      CREATE TABLE _test_partitioned_table_1
      PARTITION OF _test_partitioned_table FOR VALUES IN (1);
    SQL
  end

  describe '#ensure_unique_id' do
    subject(:ensure_unique_id) { migration.ensure_unique_id(table_name) }

    context 'when table is partitioned' do
      let(:table_name) { table_partitioned }
      let(:trigger_name) { "assign_#{table_name}_id_trigger" }
      let(:function_name) { "assign_#{table_name}_id_value" }

      context 'when trigger already exists' do
        before do
          allow(migration).to receive(:trigger_exists?)
            .with(table_name, trigger_name)
            .and_return(true)
        end

        it 'does not modify existing trigger' do
          expect(migration).not_to receive(:change_column_default)
          expect(migration).not_to receive(:create_trigger_function)
          expect(migration).not_to receive(:create_trigger)

          expect do
            ensure_unique_id
          end.not_to raise_error
        end
      end

      context 'when trigger is not defined' do
        it 'creates trigger', :aggregate_failures do
          expect(migration).to receive(:change_column_default).with(table_name, :id, nil).and_call_original
          expect(migration).to receive(:create_trigger_function).with(function_name).and_call_original
          expect(migration).to receive(:create_trigger)
            .with(table_name, trigger_name, function_name, fires: 'BEFORE INSERT')
            .and_call_original

          expect do
            ensure_unique_id
          end.not_to raise_error

          expect(migration.trigger_exists?(table_name, trigger_name)).to eq(true)
        end
      end

      context 'when table does not have a sequence' do
        before do
          allow(migration).to receive(:existing_sequence).with(table_name, :id).and_return([])
        end

        it 'raises SequenceError' do
          expect do
            ensure_unique_id
          end.to raise_error(described_class::SequenceError, /Expected to find only one sequence for/)
        end
      end

      context 'when table has multiple sequences attached to it' do
        before do
          connection.execute(<<~SQL)
            CREATE SEQUENCE second_sequence
              START 0
              INCREMENT 1
              MINVALUE 0
              OWNED BY _test_partitioned_table.id;
          SQL
        end

        it 'raises SequenceError' do
          expect do
            ensure_unique_id
          end.to raise_error(described_class::SequenceError, /Expected to find only one sequence/)
        end
      end
    end
  end
end

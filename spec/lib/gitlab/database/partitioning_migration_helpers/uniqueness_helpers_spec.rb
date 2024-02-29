# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PartitioningMigrationHelpers::UniquenessHelpers, feature_category: :database do
  let(:migration) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  let(:connection) { ActiveRecord::Base.connection }
  let(:table_name) { '_test_partitioned_table' }
  let(:trigger_name) { "assign_#{table_name}_id_trigger" }
  let(:function_name) { "assign_#{table_name}_id_value" }
  let(:seq_name) { '_test_partitioned_table_id_seq' }

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
    subject(:ensure_unique_id) do
      migration.ensure_unique_id(table_name, seq: seq_name)
    end

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
        connection.execute(<<~SQL)
          DROP SEQUENCE IF EXISTS #{seq_name} CASCADE;
        SQL
      end

      it { expect { ensure_unique_id }.to raise_error(ActiveRecord::RecordNotFound) }
    end
  end

  describe '#revert_ensure_unique_id' do
    subject(:revert_ensure_unique_id) do
      migration.revert_ensure_unique_id(table_name, seq: seq_name)
    end

    before do
      migration.ensure_unique_id(table_name, seq: seq_name)
    end

    it 'adds back the default function' do
      expect { revert_ensure_unique_id }
        .to change { default_function }
        .from(nil).to("nextval('#{seq_name}'::regclass)")
    end

    it 'removes the trigger' do
      expect { revert_ensure_unique_id }
        .to change { migration.trigger_exists?(table_name, trigger_name) }
        .from(true).to(false)
    end

    it 'removes the function' do
      expect { revert_ensure_unique_id }
        .to change { migration.function_exists?(function_name) }
        .from(true).to(false)
    end

    def default_function
      connection.columns(table_name)
        .find { |col| col.name == "id" }
        .default_function
    end
  end
end

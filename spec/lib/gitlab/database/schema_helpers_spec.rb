# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaHelpers, feature_category: :database do
  let(:connection) { ApplicationRecord.connection }
  let(:migration_context) do
    ActiveRecord::Migration
      .new
      .extend(described_class)
      .extend(Gitlab::Database::MigrationHelpers)
  end

  describe '#reset_trigger_function' do
    let(:trigger_function_name) { 'existing_trigger_function' }

    before do
      connection.execute(<<~SQL)
        CREATE FUNCTION #{trigger_function_name}() RETURNS trigger
            LANGUAGE plpgsql
            AS $$
        BEGIN
          NEW."bigint_column" := NEW."integer_column";
          RETURN NEW;
        END;
        $$;
      SQL
    end

    it 'resets' do
      recorder = ActiveRecord::QueryRecorder.new do
        migration_context.reset_trigger_function(trigger_function_name)
      end
      expect(recorder.log).to include(/ALTER FUNCTION "existing_trigger_function" RESET ALL/)
    end
  end

  describe '#reset_all_trigger_functions' do
    let(:table_name) { '_test_table_for_triggers' }
    let(:triggers) { [] }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (
          id serial PRIMARY KEY
        );
      SQL

      triggers.pluck(:function).uniq.each do |function_name|
        migration_context.create_trigger_function(function_name) { "RETURN NEW;" }
      end

      triggers.each do |trigger|
        migration_context.create_trigger(table_name, trigger[:name], trigger[:function],
          fires: 'BEFORE INSERT OR UPDATE')
      end
    end

    context 'when no triggers exist' do
      let(:triggers) { [] }

      it 'does not reset any trigger functions' do
        expect(migration_context).not_to receive(:reset_trigger_function)
        migration_context.reset_all_trigger_functions(table_name)
      end
    end

    context 'when one trigger exists' do
      let(:triggers) do
        [
          { name: 'test_trigger_1', function: 'test_function_1' }
        ]
      end

      it 'resets the single trigger function' do
        expect(migration_context).to receive(:reset_trigger_function).with('test_function_1').once.and_call_original
        migration_context.reset_all_trigger_functions(table_name)
      end
    end

    context 'when multiple triggers exist' do
      let(:triggers) do
        [
          { name: 'test_trigger_1', function: 'test_function_1' },
          { name: 'test_trigger_2', function: 'test_function_2' }
        ]
      end

      it 'resets multiple trigger functions' do
        expect(migration_context).to receive(:reset_trigger_function).with('test_function_1').once.and_call_original
        expect(migration_context).to receive(:reset_trigger_function).with('test_function_2').once.and_call_original
        migration_context.reset_all_trigger_functions(table_name)
      end
    end

    context 'when different triggers use the same function' do
      let(:shared_function) { 'shared_trigger_function' }

      let(:triggers) do
        [
          { name: 'test_trigger_1', function: shared_function },
          { name: 'test_trigger_2', function: shared_function }
        ]
      end

      it 'resets the function only once' do
        expect(migration_context).to receive(:reset_trigger_function).with(shared_function).once.and_call_original
        migration_context.reset_all_trigger_functions(table_name)
      end
    end
  end
end

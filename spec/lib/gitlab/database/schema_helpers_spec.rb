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

  describe '#trigger_exists?' do
    let(:table_name) { '_test_trigger_exists_table' }
    let(:trigger_name) { '_test_trigger' }
    let(:function_name) { '_test_trigger_fn' }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (id serial PRIMARY KEY);

        CREATE FUNCTION #{function_name}() RETURNS trigger
          LANGUAGE plpgsql AS $$ BEGIN RETURN NEW; END $$;

        CREATE TRIGGER #{trigger_name}
          BEFORE INSERT ON #{table_name}
          FOR EACH ROW EXECUTE FUNCTION #{function_name}();
      SQL
    end

    shared_examples 'trigger existence check' do
      it 'returns true when the trigger exists' do
        expect(migration_context.trigger_exists?(table_name, trigger_name)).to be(true)
      end

      it 'returns false when the trigger does not exist' do
        expect(migration_context.trigger_exists?(table_name, 'nonexistent')).to be(false)
      end
    end

    context 'when postgres_triggers view exists' do
      include_examples 'trigger existence check'
    end

    context 'when postgres_triggers view does not exist' do
      before do
        allow(connection).to receive(:view_exists?).and_call_original
        allow(connection).to receive(:view_exists?).with(:postgres_triggers).and_return(false)
      end

      include_examples 'trigger existence check'
    end
  end

  describe '#find_table_triggers' do
    let(:table_name) { '_test_find_triggers_table' }
    let(:trigger_name) { '_test_find_trigger' }
    let(:function_name) { '_test_find_trigger_fn' }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (id serial PRIMARY KEY);

        CREATE FUNCTION #{function_name}() RETURNS trigger
          LANGUAGE plpgsql AS $$ BEGIN RETURN NEW; END $$;

        CREATE TRIGGER #{trigger_name}
          BEFORE INSERT ON #{table_name}
          FOR EACH ROW EXECUTE FUNCTION #{function_name}();
      SQL
    end

    shared_examples 'find triggers check' do
      it 'returns triggers for the table' do
        triggers = migration_context.send(:find_table_triggers, table_name)

        expect(triggers).to contain_exactly(a_hash_including('function_name' => function_name))
      end

      it 'returns an empty result for a table with no triggers' do
        connection.execute("DROP TRIGGER #{trigger_name} ON #{table_name}")
        triggers = migration_context.send(:find_table_triggers, table_name)

        expect(triggers).to be_empty
      end
    end

    context 'when postgres_triggers view exists' do
      include_examples 'find triggers check'
    end

    context 'when postgres_triggers view does not exist' do
      before do
        allow(connection).to receive(:view_exists?).and_call_original
        allow(connection).to receive(:view_exists?).with(:postgres_triggers).and_return(false)
      end

      include_examples 'find triggers check'
    end
  end
end

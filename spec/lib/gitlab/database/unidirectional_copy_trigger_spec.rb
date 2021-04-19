# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::UnidirectionalCopyTrigger do
  include Database::TriggerHelpers

  let(:table_name) { '_test_table' }
  let(:connection) { ActiveRecord::Base.connection }
  let(:copy_trigger) { described_class.on_table(table_name) }

  describe '#name' do
    context 'when a single column name is given' do
      subject(:trigger_name) { copy_trigger.name('id', 'other_id') }

      it 'returns the trigger name' do
        expect(trigger_name).to eq('trigger_cfce7a56a9d6')
      end
    end

    context 'when multiple column names are given' do
      subject(:trigger_name) { copy_trigger.name(%w[id fk_id], %w[other_id other_fk_id]) }

      it 'returns the trigger name' do
        expect(trigger_name).to eq('trigger_166626e51481')
      end
    end

    context 'when a different number of new and old column names are given' do
      it 'raises an error' do
        expect do
          copy_trigger.name(%w[id fk_id], %w[other_id])
        end.to raise_error(ArgumentError, 'number of source and destination columns must match')
      end
    end
  end

  describe '#create' do
    let(:model) { Class.new(ActiveRecord::Base) }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (
          id serial NOT NULL PRIMARY KEY,
          other_id integer,
          fk_id bigint,
          other_fk_id bigint);
      SQL

      model.table_name = table_name
    end

    context 'when a single column name is given' do
      let(:trigger_name) { 'trigger_cfce7a56a9d6' }

      it 'creates the trigger and function' do
        expect_function_not_to_exist(trigger_name)
        expect_trigger_not_to_exist(table_name, trigger_name)

        copy_trigger.create('id', 'other_id')

        expect_function_to_exist(trigger_name)
        expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])
      end

      it 'properly copies the column data using the trigger function' do
        copy_trigger.create('id', 'other_id')

        record = model.create!(id: 10)
        expect(record.reload).to have_attributes(other_id: 10)

        record.update!({ id: 20 })
        expect(record.reload).to have_attributes(other_id: 20)
      end
    end

    context 'when multiple column names are given' do
      let(:trigger_name) { 'trigger_166626e51481' }

      it 'creates the trigger and function to set all the columns' do
        expect_function_not_to_exist(trigger_name)
        expect_trigger_not_to_exist(table_name, trigger_name)

        copy_trigger.create(%w[id fk_id], %w[other_id other_fk_id])

        expect_function_to_exist(trigger_name)
        expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])
      end

      it 'properly copies the columns using the trigger function' do
        copy_trigger.create(%w[id fk_id], %w[other_id other_fk_id])

        record = model.create!(id: 10, fk_id: 20)
        expect(record.reload).to have_attributes(other_id: 10, other_fk_id: 20)

        record.update!(id: 30, fk_id: 50)
        expect(record.reload).to have_attributes(other_id: 30, other_fk_id: 50)
      end
    end

    context 'when a custom trigger name is given' do
      let(:trigger_name) { '_test_trigger' }

      it 'creates the trigger and function with the custom name' do
        expect_function_not_to_exist(trigger_name)
        expect_trigger_not_to_exist(table_name, trigger_name)

        copy_trigger.create('id', 'other_id', trigger_name: trigger_name)

        expect_function_to_exist(trigger_name)
        expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])
      end
    end

    context 'when the trigger function already exists' do
      let(:trigger_name) { 'trigger_cfce7a56a9d6' }

      it 'does not raise an error' do
        expect_function_not_to_exist(trigger_name)
        expect_trigger_not_to_exist(table_name, trigger_name)

        copy_trigger.create('id', 'other_id')

        expect_function_to_exist(trigger_name)
        expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])

        copy_trigger.create('id', 'other_id')

        expect_function_to_exist(trigger_name)
        expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])
      end
    end

    context 'when a different number of new and old column names are given' do
      it 'raises an error' do
        expect do
          copy_trigger.create(%w[id fk_id], %w[other_id])
        end.to raise_error(ArgumentError, 'number of source and destination columns must match')
      end
    end
  end

  describe '#drop' do
    let(:trigger_name) { '_test_trigger' }

    before do
      connection.execute(<<~SQL)
        CREATE TABLE #{table_name} (
          id serial NOT NULL PRIMARY KEY,
          other_id integer NOT NULL);

        CREATE FUNCTION #{trigger_name}()
        RETURNS trigger
        LANGUAGE plpgsql AS
        $$
        BEGIN
          RAISE NOTICE 'hello';
          RETURN NEW;
        END
        $$;

        CREATE TRIGGER #{trigger_name}
        BEFORE INSERT OR UPDATE
        ON #{table_name}
        FOR EACH ROW
        EXECUTE FUNCTION #{trigger_name}();
      SQL
    end

    it 'drops the trigger and function for the given arguments' do
      expect_function_to_exist(trigger_name)
      expect_valid_function_trigger(table_name, trigger_name, trigger_name, before: %w[insert update])

      copy_trigger.drop(trigger_name)

      expect_trigger_not_to_exist(table_name, trigger_name)
      expect_function_not_to_exist(trigger_name)
    end

    context 'when the trigger does not exist' do
      it 'does not raise an error' do
        copy_trigger.drop(trigger_name)

        expect_trigger_not_to_exist(table_name, trigger_name)
        expect_function_not_to_exist(trigger_name)

        copy_trigger.drop(trigger_name)
      end
    end
  end
end

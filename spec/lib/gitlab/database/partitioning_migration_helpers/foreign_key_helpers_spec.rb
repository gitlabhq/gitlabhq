# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Database::PartitioningMigrationHelpers::ForeignKeyHelpers do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end
  let_it_be(:connection) { ActiveRecord::Base.connection }
  let(:referenced_table) { :issues }
  let(:function_name) { '_test_partitioned_foreign_keys_function' }
  let(:trigger_name) { '_test_partitioned_foreign_keys_trigger' }

  before do
    allow(model).to receive(:puts)
    allow(model).to receive(:fk_function_name).and_return(function_name)
    allow(model).to receive(:fk_trigger_name).and_return(trigger_name)
  end

  describe 'adding a foreign key' do
    before do
      allow(model).to receive(:transaction_open?).and_return(false)
    end

    context 'when the table has no foreign keys' do
      it 'creates a trigger function to handle the single cascade' do
        model.add_partitioned_foreign_key :issue_assignees, referenced_table

        expect_function_to_contain(function_name, 'delete from issue_assignees where issue_id = old.id')
        expect_valid_function_trigger(trigger_name, function_name)
      end
    end

    context 'when the table already has foreign keys' do
      context 'when the foreign key is from a different table' do
        before do
          model.add_partitioned_foreign_key :issue_assignees, referenced_table
        end

        it 'creates a trigger function to handle the multiple cascades' do
          model.add_partitioned_foreign_key :epic_issues, referenced_table

          expect_function_to_contain(function_name,
            'delete from issue_assignees where issue_id = old.id',
            'delete from epic_issues where issue_id = old.id')
          expect_valid_function_trigger(trigger_name, function_name)
        end
      end

      context 'when the foreign key is from the same table' do
        before do
          model.add_partitioned_foreign_key :issues, referenced_table, column: :moved_to_id
        end

        context 'when the foreign key is from a different column' do
          it 'creates a trigger function to handle the multiple cascades' do
            model.add_partitioned_foreign_key :issues, referenced_table, column: :duplicated_to_id

            expect_function_to_contain(function_name,
              'delete from issues where moved_to_id = old.id',
              'delete from issues where duplicated_to_id = old.id')
            expect_valid_function_trigger(trigger_name, function_name)
          end
        end

        context 'when the foreign key is from the same column' do
          it 'ignores the duplicate and properly recreates the trigger function' do
            model.add_partitioned_foreign_key :issues, referenced_table, column: :moved_to_id

            expect_function_to_contain(function_name, 'delete from issues where moved_to_id = old.id')
            expect_valid_function_trigger(trigger_name, function_name)
          end
        end
      end
    end

    context 'when the foreign key is set to nullify' do
      it 'creates a trigger function that nullifies the foreign key' do
        model.add_partitioned_foreign_key :issue_assignees, referenced_table, on_delete: :nullify

        expect_function_to_contain(function_name, 'update issue_assignees set issue_id = null where issue_id = old.id')
        expect_valid_function_trigger(trigger_name, function_name)
      end
    end

    context 'when the referencing column is a custom value' do
      it 'creates a trigger function with the correct column name' do
        model.add_partitioned_foreign_key :issues, referenced_table, column: :duplicated_to_id

        expect_function_to_contain(function_name, 'delete from issues where duplicated_to_id = old.id')
        expect_valid_function_trigger(trigger_name, function_name)
      end
    end

    context 'when the referenced column is a custom value' do
      let(:referenced_table) { :user_details }

      it 'creates a trigger function with the correct column name' do
        model.add_partitioned_foreign_key :user_preferences, referenced_table, column: :user_id, primary_key: :user_id

        expect_function_to_contain(function_name, 'delete from user_preferences where user_id = old.user_id')
        expect_valid_function_trigger(trigger_name, function_name)
      end
    end

    context 'when the given key definition is invalid' do
      it 'raises an error with the appropriate message' do
        expect do
          model.add_partitioned_foreign_key :issue_assignees, referenced_table, column: :not_a_real_issue_id
        end.to raise_error(/From column must be a valid column/)
      end
    end

    context 'when run inside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.add_partitioned_foreign_key :issue_assignees, referenced_table
        end.to raise_error(/can not be run inside a transaction/)
      end
    end
  end

  context 'removing a foreign key' do
    before do
      allow(model).to receive(:transaction_open?).and_return(false)
    end

    context 'when the table has multiple foreign keys' do
      before do
        model.add_partitioned_foreign_key :issue_assignees, referenced_table
        model.add_partitioned_foreign_key :epic_issues, referenced_table
      end

      it 'creates a trigger function without the removed cascade' do
        expect_function_to_contain(function_name,
          'delete from issue_assignees where issue_id = old.id',
          'delete from epic_issues where issue_id = old.id')
        expect_valid_function_trigger(trigger_name, function_name)

        model.remove_partitioned_foreign_key :issue_assignees, referenced_table

        expect_function_to_contain(function_name, 'delete from epic_issues where issue_id = old.id')
        expect_valid_function_trigger(trigger_name, function_name)
      end
    end

    context 'when the table has only one remaining foreign key' do
      before do
        model.add_partitioned_foreign_key :issue_assignees, referenced_table
      end

      it 'removes the trigger function altogether' do
        expect_function_to_contain(function_name, 'delete from issue_assignees where issue_id = old.id')
        expect_valid_function_trigger(trigger_name, function_name)

        model.remove_partitioned_foreign_key :issue_assignees, referenced_table

        expect(find_function_def(function_name)).to be_nil
        expect(find_trigger_def(trigger_name)).to be_nil
      end
    end

    context 'when the foreign key does not exist' do
      before do
        model.add_partitioned_foreign_key :issue_assignees, referenced_table
      end

      it 'ignores the invalid key and properly recreates the trigger function' do
        expect_function_to_contain(function_name, 'delete from issue_assignees where issue_id = old.id')
        expect_valid_function_trigger(trigger_name, function_name)

        model.remove_partitioned_foreign_key :issues, referenced_table, column: :moved_to_id

        expect_function_to_contain(function_name, 'delete from issue_assignees where issue_id = old.id')
        expect_valid_function_trigger(trigger_name, function_name)
      end
    end

    context 'when run outside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.remove_partitioned_foreign_key :issue_assignees, referenced_table
        end.to raise_error(/can not be run inside a transaction/)
      end
    end
  end

  def expect_function_to_contain(name, *statements)
    return_stmt, *body_stmts = parsed_function_statements(name).reverse

    expect(return_stmt).to eq('return old')
    expect(body_stmts).to contain_exactly(*statements)
  end

  def expect_valid_function_trigger(name, fn_name)
    event, activation, definition = cleaned_trigger_def(name)

    expect(event).to eq('delete')
    expect(activation).to eq('after')
    expect(definition).to eq("execute procedure #{fn_name}()")
  end

  def parsed_function_statements(name)
    cleaned_definition = find_function_def(name)['fn_body'].downcase.gsub(/\s+/, ' ')
    statements = cleaned_definition.sub(/\A\s*begin\s*(.*)\s*end\s*\Z/, "\\1")
    statements.split(';').map! { |stmt| stmt.strip.presence }.compact!
  end

  def find_function_def(name)
    connection.execute("select prosrc as fn_body from pg_proc where proname = '#{name}';").first
  end

  def cleaned_trigger_def(name)
    find_trigger_def(name).values_at('event', 'activation', 'definition').map!(&:downcase)
  end

  def find_trigger_def(name)
    connection.execute(<<~SQL).first
      select
        string_agg(event_manipulation, ',') as event,
        action_timing as activation,
        action_statement as definition
      from information_schema.triggers
      where trigger_name = '#{name}'
      group by 2, 3
    SQL
  end
end

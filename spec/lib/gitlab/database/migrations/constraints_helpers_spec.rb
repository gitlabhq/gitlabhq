# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::ConstraintsHelpers do
  let(:model) do
    ActiveRecord::Migration.new.extend(described_class)
  end

  before do
    allow(model).to receive(:puts)
  end

  describe '#check_constraint_name' do
    it 'returns a valid constraint name' do
      name = model.check_constraint_name(
        :this_is_a_very_long_table_name,
        :with_a_very_long_column_name,
        :with_a_very_long_type
      )

      expect(name).to be_an_instance_of(String)
      expect(name).to start_with('check_')
      expect(name.length).to eq(16)
    end
  end

  describe '#check_constraint_exists?', :aggregate_failures do
    before do
      ActiveRecord::Migration.connection.execute(<<~SQL)
        ALTER TABLE projects ADD CONSTRAINT check_1 CHECK (char_length(path) <= 5) NOT VALID;
        CREATE SCHEMA new_test_schema;
        CREATE TABLE new_test_schema.projects (id integer, name character varying);
        ALTER TABLE new_test_schema.projects ADD CONSTRAINT check_2 CHECK (char_length(name) <= 5);
      SQL
    end

    it 'returns true if a constraint exists' do
      expect(model)
        .to be_check_constraint_exists(:projects, 'check_1')

      expect(described_class)
        .to be_check_constraint_exists(:projects, 'check_1', connection: model.connection)
    end

    it 'returns true if a constraint exists in the specified non-current schema' do
      expect(model)
        .to be_check_constraint_exists('new_test_schema.projects', 'check_2')

      expect(described_class)
        .to be_check_constraint_exists('new_test_schema.projects', 'check_2', connection: model.connection)
    end

    it 'returns false if a constraint does not exist' do
      expect(model)
        .not_to be_check_constraint_exists(:projects, 'this_does_not_exist')

      expect(described_class)
        .not_to be_check_constraint_exists(:projects, 'this_does_not_exist', connection: model.connection)
    end

    it 'returns false if a constraint with the same name exists in another table' do
      expect(model)
        .not_to be_check_constraint_exists(:users, 'check_1')

      expect(described_class)
        .not_to be_check_constraint_exists(:users, 'check_1', connection: model.connection)
    end

    it 'returns false if a constraint with the same name exists for the same table in another schema' do
      expect(model)
        .not_to be_check_constraint_exists(:projects, 'check_2')

      expect(described_class)
        .not_to be_check_constraint_exists(:projects, 'check_2', connection: model.connection)
    end
  end

  describe '#add_check_constraint' do
    before do
      allow(model).to receive(:check_constraint_exists?).and_return(false)
    end

    context 'when constraint name validation' do
      it 'raises an error when too long' do
        expect do
          model.add_check_constraint(
            :test_table,
            'name IS NOT NULL',
            'a' * (Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH + 1)
          )
        end.to raise_error(RuntimeError)
      end

      it 'does not raise error when the length is acceptable' do
        constraint_name = 'a' * Gitlab::Database::MigrationHelpers::MAX_IDENTIFIER_NAME_LENGTH

        expect(model).to receive(:transaction_open?).and_return(false)
        expect(model).to receive(:check_constraint_exists?).and_return(false)
        expect(model).to receive(:with_lock_retries).and_call_original
        expect(model).to receive(:execute).with(/ADD CONSTRAINT/)

        model.add_check_constraint(
          :test_table,
          'name IS NOT NULL',
          constraint_name,
          validate: false
        )
      end
    end

    context 'when inside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.add_check_constraint(
            :test_table,
            'name IS NOT NULL',
            'check_name_not_null'
          )
        end.to raise_error(RuntimeError)
      end
    end

    context 'when outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      context 'when the constraint is already defined in the database' do
        it 'does not create a constraint' do
          expect(model).to receive(:check_constraint_exists?)
                       .with(:test_table, 'check_name_not_null')
                       .and_return(true)

          expect(model).not_to receive(:execute).with(/ADD CONSTRAINT/)

          # setting validate: false to only focus on the ADD CONSTRAINT command
          model.add_check_constraint(
            :test_table,
            'name IS NOT NULL',
            'check_name_not_null',
            validate: false
          )
        end
      end

      context 'when the constraint is not defined in the database' do
        it 'creates the constraint' do
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:execute).with(/ADD CONSTRAINT check_name_not_null/)

          # setting validate: false to only focus on the ADD CONSTRAINT command
          model.add_check_constraint(
            :test_table,
            'char_length(name) <= 255',
            'check_name_not_null',
            validate: false
          )
        end

        context 'with a schema-prefixed table' do
          it 'includes the schema in the ADD CONSTRAINT query' do
            expect(model).to receive(:with_lock_retries).and_call_original
            expect(model).to receive(:execute).with(/ALTER TABLE other_schema.test_table\s+ADD CONSTRAINT/)

            # setting validate: false to only focus on the ADD CONSTRAINT command
            model.add_check_constraint(
              'other_schema.test_table',
              'char_length(name) <= 255',
              'check_name_not_null',
              validate: false
            )
          end
        end
      end

      context 'when validate is not provided' do
        it 'performs validation' do
          expect(model).to receive(:check_constraint_exists?)
                       .with(:test_table, 'check_name_not_null')
                       .and_return(false).exactly(1)

          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:execute).with(/ADD CONSTRAINT check_name_not_null/)

          # we need the check constraint to exist so that the validation proceeds
          expect(model).to receive(:check_constraint_exists?)
                       .with(:test_table, 'check_name_not_null')
                       .and_return(true).exactly(1)

          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

          model.add_check_constraint(
            :test_table,
            'char_length(name) <= 255',
            'check_name_not_null'
          )
        end
      end

      context 'when validate is provided with a falsey value' do
        it 'skips validation' do
          expect(model).not_to receive(:disable_statement_timeout)
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:execute).with(/ADD CONSTRAINT/)
          expect(model).not_to receive(:execute).with(/VALIDATE CONSTRAINT/)

          model.add_check_constraint(
            :test_table,
            'char_length(name) <= 255',
            'check_name_not_null',
            validate: false
          )
        end
      end

      context 'when validate is provided with a truthy value' do
        it 'performs validation' do
          expect(model).to receive(:check_constraint_exists?)
                       .with(:test_table, 'check_name_not_null')
                       .and_return(false).exactly(1)

          expect(model).to receive(:disable_statement_timeout).and_call_original
          expect(model).to receive(:statement_timeout_disabled?).and_return(false)
          expect(model).to receive(:execute).with(/SET statement_timeout TO/)
          expect(model).to receive(:with_lock_retries).and_call_original
          expect(model).to receive(:execute).with(/ADD CONSTRAINT check_name_not_null/)

          expect(model).to receive(:check_constraint_exists?)
                       .with(:test_table, 'check_name_not_null')
                       .and_return(true).exactly(1)

          expect(model).to receive(:execute).ordered.with(/VALIDATE CONSTRAINT/)
          expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

          model.add_check_constraint(
            :test_table,
            'char_length(name) <= 255',
            'check_name_not_null',
            validate: true
          )
        end
      end
    end
  end

  describe '#validate_check_constraint' do
    context 'when the constraint does not exist' do
      it 'raises an error' do
        error_message = /Could not find check constraint "check_1" on table "test_table"/

        expect(model).to receive(:check_constraint_exists?).and_return(false)

        expect do
          model.validate_check_constraint(:test_table, 'check_1')
        end.to raise_error(RuntimeError, error_message)
      end
    end

    context 'when the constraint exists' do
      it 'performs validation' do
        validate_sql = /ALTER TABLE test_table VALIDATE CONSTRAINT check_name/

        expect(model).to receive(:check_constraint_exists?).and_return(true)
        expect(model).to receive(:disable_statement_timeout).and_call_original
        expect(model).to receive(:statement_timeout_disabled?).and_return(false)
        expect(model).to receive(:execute).with(/SET statement_timeout TO/)
        expect(model).to receive(:execute).ordered.with(validate_sql)
        expect(model).to receive(:execute).ordered.with(/RESET statement_timeout/)

        model.validate_check_constraint(:test_table, 'check_name')
      end
    end
  end

  describe '#remove_check_constraint' do
    before do
      allow(model).to receive(:transaction_open?).and_return(false)
    end

    it 'removes the constraint' do
      drop_sql = /ALTER TABLE test_table\s+DROP CONSTRAINT IF EXISTS check_name/

      expect(model).to receive(:with_lock_retries).and_call_original
      expect(model).to receive(:execute).with(drop_sql)

      model.remove_check_constraint(:test_table, 'check_name')
    end
  end

  describe '#copy_check_constraints' do
    context 'when inside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.copy_check_constraints(:test_table, :old_column, :new_column)
        end.to raise_error(RuntimeError)
      end
    end

    context 'when outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
        allow(model).to receive(:column_exists?).and_return(true)
      end

      let(:old_column_constraints) do
        [
          {
            'schema_name' => 'public',
            'table_name' => 'test_table',
            'column_name' => 'old_column',
            'constraint_name' => 'check_d7d49d475d',
            'constraint_def' => 'CHECK ((old_column IS NOT NULL))'
          },
          {
            'schema_name' => 'public',
            'table_name' => 'test_table',
            'column_name' => 'old_column',
            'constraint_name' => 'check_48560e521e',
            'constraint_def' => 'CHECK ((char_length(old_column) <= 255))'
          },
          {
            'schema_name' => 'public',
            'table_name' => 'test_table',
            'column_name' => 'old_column',
            'constraint_name' => 'custom_check_constraint',
            'constraint_def' => 'CHECK (((old_column IS NOT NULL) AND (another_column IS NULL)))'
          },
          {
            'schema_name' => 'public',
            'table_name' => 'test_table',
            'column_name' => 'old_column',
            'constraint_name' => 'not_valid_check_constraint',
            'constraint_def' => 'CHECK ((old_column IS NOT NULL)) NOT VALID'
          }
        ]
      end

      it 'copies check constraints from one column to another' do
        allow(model).to receive(:check_constraints_for)
        .with(:test_table, :old_column, schema: nil)
          .and_return(old_column_constraints)

        allow(model).to receive(:not_null_constraint_name).with(:test_table, :new_column)
          .and_return('check_1')

        allow(model).to receive(:text_limit_name).with(:test_table, :new_column)
          .and_return('check_2')

        allow(model).to receive(:check_constraint_name)
          .with(:test_table, :new_column, 'copy_check_constraint')
          .and_return('check_3')

        expect(model).to receive(:add_check_constraint)
          .with(
            :test_table,
            '(new_column IS NOT NULL)',
            'check_1',
            validate: true
          ).once

        expect(model).to receive(:add_check_constraint)
          .with(
            :test_table,
            '(char_length(new_column) <= 255)',
            'check_2',
            validate: true
          ).once

        expect(model).to receive(:add_check_constraint)
          .with(
            :test_table,
            '((new_column IS NOT NULL) AND (another_column IS NULL))',
            'check_3',
            validate: true
          ).once

        expect(model).to receive(:add_check_constraint)
          .with(
            :test_table,
            '(new_column IS NOT NULL)',
            'check_1',
            validate: false
          ).once

        model.copy_check_constraints(:test_table, :old_column, :new_column)
      end

      it 'does nothing if there are no constraints defined for the old column' do
        allow(model).to receive(:check_constraints_for)
        .with(:test_table, :old_column, schema: nil)
          .and_return([])

        expect(model).not_to receive(:add_check_constraint)

        model.copy_check_constraints(:test_table, :old_column, :new_column)
      end

      it 'raises an error when the orginating column does not exist' do
        allow(model).to receive(:column_exists?).with(:test_table, :old_column).and_return(false)

        error_message = /Column old_column does not exist on test_table/

        expect do
          model.copy_check_constraints(:test_table, :old_column, :new_column)
        end.to raise_error(RuntimeError, error_message)
      end

      it 'raises an error when the target column does not exist' do
        allow(model).to receive(:column_exists?).with(:test_table, :new_column).and_return(false)

        error_message = /Column new_column does not exist on test_table/

        expect do
          model.copy_check_constraints(:test_table, :old_column, :new_column)
        end.to raise_error(RuntimeError, error_message)
      end
    end
  end

  describe '#add_text_limit' do
    context 'when it is called with the default options' do
      it 'calls add_check_constraint with an infered constraint name and validate: true' do
        constraint_name = model.check_constraint_name(:test_table, :name, 'max_length')
        check = "char_length(name) <= 255"

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:add_check_constraint)
                     .with(:test_table, check, constraint_name, validate: true)

        model.add_text_limit(:test_table, :name, 255)
      end
    end

    context 'when all parameters are provided' do
      it 'calls add_check_constraint with the correct parameters' do
        constraint_name = 'check_name_limit'
        check = "char_length(name) <= 255"

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:add_check_constraint)
                     .with(:test_table, check, constraint_name, validate: false)

        model.add_text_limit(
          :test_table,
          :name,
          255,
          constraint_name: constraint_name,
          validate: false
        )
      end
    end
  end

  describe '#validate_text_limit' do
    context 'when constraint_name is not provided' do
      it 'calls validate_check_constraint with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table, :name, 'max_length')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:validate_check_constraint)
                     .with(:test_table, constraint_name)

        model.validate_text_limit(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls validate_check_constraint with the correct parameters' do
        constraint_name = 'check_name_limit'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:validate_check_constraint)
                     .with(:test_table, constraint_name)

        model.validate_text_limit(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#remove_text_limit' do
    context 'when constraint_name is not provided' do
      it 'calls remove_check_constraint with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table, :name, 'max_length')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:remove_check_constraint)
                     .with(:test_table, constraint_name)

        model.remove_text_limit(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls remove_check_constraint with the correct parameters' do
        constraint_name = 'check_name_limit'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:remove_check_constraint)
                     .with(:test_table, constraint_name)

        model.remove_text_limit(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#check_text_limit_exists?' do
    context 'when constraint_name is not provided' do
      it 'calls check_constraint_exists? with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table, :name, 'max_length')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:check_constraint_exists?)
                     .with(:test_table, constraint_name)

        model.check_text_limit_exists?(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls check_constraint_exists? with the correct parameters' do
        constraint_name = 'check_name_limit'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:check_constraint_exists?)
                     .with(:test_table, constraint_name)

        model.check_text_limit_exists?(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#add_not_null_constraint' do
    context 'when it is called with the default options' do
      it 'calls add_check_constraint with an inferred constraint name and validate: true' do
        constraint_name = model.check_constraint_name(:test_table, :name, 'not_null')
        check = "name IS NOT NULL"

        expect(model).to receive(:column_is_nullable?).and_return(true)
        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:add_check_constraint)
                     .with(:test_table, check, constraint_name, validate: true)

        model.add_not_null_constraint(:test_table, :name)
      end
    end

    context 'when all parameters are provided' do
      it 'calls add_check_constraint with the correct parameters' do
        constraint_name = 'check_name_not_null'
        check = "name IS NOT NULL"

        expect(model).to receive(:column_is_nullable?).and_return(true)
        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:add_check_constraint)
                     .with(:test_table, check, constraint_name, validate: false)

        model.add_not_null_constraint(
          :test_table,
          :name,
          constraint_name: constraint_name,
          validate: false
        )
      end
    end

    context 'when the column is defined as NOT NULL' do
      it 'does not add a check constraint' do
        expect(model).to receive(:column_is_nullable?).and_return(false)
        expect(model).not_to receive(:check_constraint_name)
        expect(model).not_to receive(:add_check_constraint)

        model.add_not_null_constraint(:test_table, :name)
      end
    end
  end

  describe '#validate_not_null_constraint' do
    context 'when constraint_name is not provided' do
      it 'calls validate_check_constraint with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table, :name, 'not_null')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:validate_check_constraint)
                     .with(:test_table, constraint_name)

        model.validate_not_null_constraint(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls validate_check_constraint with the correct parameters' do
        constraint_name = 'check_name_not_null'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:validate_check_constraint)
                     .with(:test_table, constraint_name)

        model.validate_not_null_constraint(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#remove_not_null_constraint' do
    context 'when constraint_name is not provided' do
      it 'calls remove_check_constraint with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table, :name, 'not_null')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:remove_check_constraint)
                     .with(:test_table, constraint_name)

        model.remove_not_null_constraint(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls remove_check_constraint with the correct parameters' do
        constraint_name = 'check_name_not_null'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:remove_check_constraint)
                     .with(:test_table, constraint_name)

        model.remove_not_null_constraint(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#check_not_null_constraint_exists?' do
    context 'when constraint_name is not provided' do
      it 'calls check_constraint_exists? with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table, :name, 'not_null')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:check_constraint_exists?)
                     .with(:test_table, constraint_name)

        model.check_not_null_constraint_exists?(:test_table, :name)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls check_constraint_exists? with the correct parameters' do
        constraint_name = 'check_name_not_null'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:check_constraint_exists?)
                     .with(:test_table, constraint_name)

        model.check_not_null_constraint_exists?(:test_table, :name, constraint_name: constraint_name)
      end
    end
  end

  describe '#add_multi_column_not_null_constraint' do
    context 'when it is called with the default options' do
      it 'calls add_check_constraint with an infered constraint name and validate: true' do
        constraint_name = model.check_constraint_name(:test_table, 'email_name', 'num_nonnulls')
        check = 'num_nonnulls(email, name) = 1'

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:add_check_constraint)
                     .with(:test_table, check, constraint_name, validate: true)

        model.add_multi_column_not_null_constraint(:test_table, :name, :email)
      end
    end

    context 'when all parameters are provided' do
      it 'calls add_check_constraint with the correct parameters' do
        constraint_name = 'check_test_table_num_nonnulls'
        check = 'num_nonnulls(email, name) >= 2'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:add_check_constraint)
                     .with(:test_table, check, constraint_name, validate: false)

        model.add_multi_column_not_null_constraint(
          :test_table,
          :name, :email,
          limit: 2,
          operator: '>=',
          constraint_name: constraint_name,
          validate: false
        )
      end
    end

    context 'when only one column is supplied' do
      it 'raises an error' do
        expect do
          model.add_multi_column_not_null_constraint(:test_table, :name)
        end.to raise_error('Expected multiple columns, use add_not_null_constraint for a single column')
      end
    end
  end

  describe '#validate_multi_column_not_null_constraint' do
    context 'when constraint_name is not provided' do
      it 'calls validate_check_constraint with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table, 'email_name', 'num_nonnulls')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:validate_check_constraint)
                     .with(:test_table, constraint_name)

        model.validate_multi_column_not_null_constraint(:test_table, :name, :email)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls validate_check_constraint with the correct parameters' do
        constraint_name = 'check_name_email_num_nonnulls'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:validate_check_constraint)
                     .with(:test_table, constraint_name)

        model.validate_multi_column_not_null_constraint(:test_table, :name, :email, constraint_name: constraint_name)
      end
    end
  end

  describe '#remove_multi_column_not_null_constraint' do
    context 'when constraint_name is not provided' do
      it 'calls remove_check_constraint with an infered constraint name' do
        constraint_name = model.check_constraint_name(:test_table, 'email_name', 'num_nonnulls')

        expect(model).to receive(:check_constraint_name).and_call_original
        expect(model).to receive(:remove_check_constraint)
                     .with(:test_table, constraint_name)

        model.remove_multi_column_not_null_constraint(:test_table, :name, :email)
      end
    end

    context 'when constraint_name is provided' do
      it 'calls remove_check_constraint with the correct parameters' do
        constraint_name = 'check_name_email_num_nonnulls'

        expect(model).not_to receive(:check_constraint_name)
        expect(model).to receive(:remove_check_constraint)
                     .with(:test_table, constraint_name)

        model.remove_multi_column_not_null_constraint(:test_table, :name, :email, constraint_name: constraint_name)
      end
    end
  end

  describe '#rename_constraint' do
    it "executes the statement to rename constraint" do
      expect(model).to receive(:execute).with(
        /ALTER TABLE "test_table"\nRENAME CONSTRAINT "fk_old_name" TO "fk_new_name"/
      )

      model.rename_constraint(:test_table, :fk_old_name, :fk_new_name)
    end
  end

  describe '#drop_constraint' do
    it "executes the statement to drop the constraint" do
      expect(model).to receive(:execute).with(
        "ALTER TABLE \"test_table\" DROP CONSTRAINT \"constraint_name\" CASCADE\n"
      )

      model.drop_constraint(:test_table, :constraint_name, cascade: true)
    end

    context 'when cascade option is false' do
      it "executes the statement to drop the constraint without cascade" do
        expect(model).to receive(:execute).with("ALTER TABLE \"test_table\" DROP CONSTRAINT \"constraint_name\" \n")

        model.drop_constraint(:test_table, :constraint_name, cascade: false)
      end
    end
  end

  describe '#switch_constraint_names' do
    before do
      ActiveRecord::Migration.connection.create_table(:_test_table) do |t|
        t.references :supplier, foreign_key: { to_table: :_test_table, name: :supplier_fk }
        t.references :customer, foreign_key: { to_table: :_test_table, name: :customer_fk }
      end
    end

    context 'when inside a transaction' do
      it 'raises an error' do
        expect(model).to receive(:transaction_open?).and_return(true)

        expect do
          model.switch_constraint_names(:_test_table, :supplier_fk, :customer_fk)
        end.to raise_error(RuntimeError)
      end
    end

    context 'when outside a transaction' do
      before do
        allow(model).to receive(:transaction_open?).and_return(false)
      end

      it 'executes the statement to swap the constraint names' do
        expect { model.switch_constraint_names(:_test_table, :supplier_fk, :customer_fk) }
          .to change { constrained_column_for(:customer_fk) }.from(:customer_id).to(:supplier_id)
          .and change { constrained_column_for(:supplier_fk) }.from(:supplier_id).to(:customer_id)
      end

      def constrained_column_for(fk_name)
        Gitlab::Database::PostgresForeignKey
          .find_by!(referenced_table_name: :_test_table, name: fk_name)
          .constrained_columns
          .first
          .to_sym
      end
    end
  end
end

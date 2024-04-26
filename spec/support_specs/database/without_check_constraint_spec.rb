# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Database::WithoutCheckConstraint' do
  include MigrationsHelpers

  describe '.without_check_constraint' do
    let(:connection) { ApplicationRecord.connection }
    let(:table_name) { '_test_table' }
    let(:constraint_name) { 'check_1234' }
    let(:model) { table(table_name) }

    before do
      connection.schema_cache.clear!

      # Drop test table in case it's left from a previous execution.
      connection.exec_query("DROP TABLE IF EXISTS #{table_name}")
      # Model has an attribute called 'name' that can't be NULL.
      connection.exec_query(<<-SQL)
        CREATE TABLE #{table_name} (
          name text
          CONSTRAINT #{constraint_name} CHECK (name IS NOT NULL)
        );
      SQL
    end

    context 'with invalid table' do
      subject do
        without_check_constraint('no_such_table', constraint_name, connection: connection) {}
      end

      it 'raises exception' do
        msg = "'no_such_table' does not exist"
        expect { subject }.to raise_error(msg)
      end
    end

    context 'with invalid constraint name' do
      subject do
        without_check_constraint(table_name, 'no_such_constraint', connection: connection) {}
      end

      it 'raises exception' do
        msg = "'#{table_name}' table does not contain constraint called 'no_such_constraint'"
        expect { subject }.to raise_error(msg)
      end
    end

    context 'with constraint' do
      subject { connection.check_constraints(table_name) }

      it 'removes inside block' do
        without_check_constraint(table_name, constraint_name, connection: connection) do
          expect(subject).to be_empty
        end
      end

      it 'restores outside block' do
        saved_constraints = subject

        without_check_constraint(table_name, constraint_name, connection: connection) do
        end

        expect(subject).to eq(saved_constraints)
      end
    end

    context 'when creating an invalid record' do
      subject(:invalid_record) { model.create!(name: nil) }

      it 'enables invalid record creation inside block' do
        without_check_constraint(table_name, constraint_name, connection: connection) do
          expect(invalid_record).to be_persisted
          expect(invalid_record.name).to be_nil
        end
      end

      it 'rolls back changes made within the block' do
        without_check_constraint(table_name, constraint_name, connection: connection) do
          invalid_record
        end
        expect(model.all).to be_empty
      end
    end
  end
end

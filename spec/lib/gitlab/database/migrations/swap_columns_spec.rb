# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::SwapColumns, feature_category: :database do
  describe '#execute' do
    let(:connection) { ApplicationRecord.connection }
    let(:sql) do
      <<~SQL
        CREATE TABLE #{table} (
          id integer NOT NULL,
          #{column1} integer DEFAULT 8 NOT NULL,
          #{column2} bigint DEFAULT 100 NOT NULL
        );
      SQL
    end

    let(:migration_context) do
      Gitlab::Database::Migration[2.1]
        .new('name', 'version')
        .extend(Gitlab::Database::MigrationHelpers::Swapping)
    end

    let(:table) { :_test_swap_columns_and_defaults }
    let(:column1) { :integer_column }
    let(:column2) { :bigint_column }

    subject(:execute_service) do
      described_class.new(
        migration_context: migration_context,
        table: table,
        column1: column1,
        column2: column2
      ).execute
    end

    before do
      connection.execute(sql)
    end

    shared_examples_for 'swapping columns correctly' do
      specify do
        expect { execute_service }
          .to change { find_column_by(column1).sql_type }.from('integer').to('bigint')
          .and change { find_column_by(column2).sql_type }.from('bigint').to('integer')
      end
    end

    it_behaves_like 'swapping columns correctly'

    context 'when column names are 63 bytes' do
      let(:column1) { :int012345678901234567890123456789012345678901234567890123456789 }
      let(:column2) { :big012345678901234567890123456789012345678901234567890123456789 }

      it_behaves_like 'swapping columns correctly'
    end

    private

    def find_column_by(name)
      connection.columns(table).find { |c| c.name == name.to_s }
    end
  end
end

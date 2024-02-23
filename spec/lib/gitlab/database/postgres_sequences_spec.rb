# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::PostgresSequence, type: :model, feature_category: :database do
  # PostgresSequence does not `behaves_like 'a postgres model'` because it does not correspond 1-1 with a single entry
  # in pg_class
  let(:schema) { ActiveRecord::Base.connection.current_schema }
  let(:table_name) { '_test_table' }
  let(:table_name_without_sequence) { '_test_table_without_sequence' }
  let(:col_name) { :id }

  before do
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TABLE #{table_name} (
        id bigserial PRIMARY KEY NOT NULL
      );

      CREATE TABLE #{table_name_without_sequence} (
        id bigint PRIMARY KEY NOT NULL
      );
    SQL
  end

  describe 'scopes' do
    describe '#by_table_name' do
      context 'when table does not have a sequence' do
        it 'returns an empty collection' do
          expect(described_class.by_table_name(table_name_without_sequence)).to be_empty
        end
      end

      it 'returns the sequence for a given table' do
        expect(described_class.by_table_name(table_name).first[:table_name]).to eq(table_name)
      end
    end

    describe '#by_col_name' do
      it 'returns the sequence for a col name' do
        expect(described_class.by_col_name(col_name).first[:table_name]).to eq(table_name)
      end
    end
  end
end

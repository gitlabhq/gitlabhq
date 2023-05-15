# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Inconsistency, feature_category: :database do
  let(:validator) { Gitlab::Database::SchemaValidation::Validators::DifferentDefinitionIndexes }

  let(:database_statement) { 'CREATE INDEX index_name ON public.achievements USING btree (namespace_id)' }
  let(:structure_sql_statement) { 'CREATE INDEX index_name ON public.achievements USING btree (id)' }

  let(:structure_stmt) { PgQuery.parse(structure_sql_statement).tree.stmts.first.stmt.index_stmt }
  let(:database_stmt) { PgQuery.parse(database_statement).tree.stmts.first.stmt.index_stmt }

  let(:structure_sql_object) { Gitlab::Database::SchemaValidation::SchemaObjects::Index.new(structure_stmt) }
  let(:database_object) { Gitlab::Database::SchemaValidation::SchemaObjects::Index.new(database_stmt) }

  subject(:inconsistency) { described_class.new(validator, structure_sql_object, database_object) }

  describe '#object_name' do
    it 'returns the index name' do
      expect(inconsistency.object_name).to eq('index_name')
    end
  end

  describe '#diff' do
    it 'returns a diff between the structure.sql and the database' do
      expect(inconsistency.diff).to be_a(Diffy::Diff)
      expect(inconsistency.diff.string1).to eq("#{structure_sql_statement}\n")
      expect(inconsistency.diff.string2).to eq("#{database_statement}\n")
    end
  end

  describe '#error_message' do
    it 'returns the error message' do
      stub_const "#{validator}::ERROR_MESSAGE", 'error message %s'

      expect(inconsistency.error_message).to eq('error message index_name')
    end
  end

  describe '#type' do
    it 'returns the type of the validator' do
      expect(inconsistency.type).to eq('different_definition_indexes')
    end
  end

  describe '#table_name' do
    it 'returns the table name' do
      expect(inconsistency.table_name).to eq('achievements')
    end
  end

  describe '#object_type' do
    it 'returns the structure sql object type' do
      expect(inconsistency.object_type).to eq('Index')
    end

    context 'when the structure sql object is not available' do
      subject(:inconsistency) { described_class.new(validator, nil, database_object) }

      it 'returns the database object type' do
        expect(inconsistency.object_type).to eq('Index')
      end
    end
  end

  describe '#structure_sql_statement' do
    it 'returns structure sql statement' do
      expect(inconsistency.structure_sql_statement).to eq("#{structure_sql_statement}\n")
    end
  end

  describe '#database_statement' do
    it 'returns database statement' do
      expect(inconsistency.database_statement).to eq("#{database_statement}\n")
    end
  end

  describe '#inspect' do
    let(:expected_output) do
      <<~MSG
      ------------------------------------------------------
      The index_name index has a different statement between structure.sql and database
      Diff:
      \e[31m-CREATE INDEX index_name ON public.achievements USING btree (id)\e[0m
      \e[32m+CREATE INDEX index_name ON public.achievements USING btree (namespace_id)\e[0m

      ------------------------------------------------------
      MSG
    end

    it 'prints the inconsistency message' do
      expect(inconsistency.inspect).to eql(expected_output)
    end
  end
end

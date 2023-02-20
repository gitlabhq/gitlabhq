# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Index, feature_category: :database do
  let(:index_statement) { 'CREATE INDEX index_name ON public.achievements USING btree (namespace_id)' }

  let(:stmt) { PgQuery.parse(index_statement).tree.stmts.first.stmt.index_stmt }

  let(:index) { described_class.new(stmt) }

  describe '#name' do
    it 'returns index name' do
      expect(index.name).to eq('index_name')
    end
  end

  describe '#statement' do
    it 'returns index statement' do
      expect(index.statement).to eq(index_statement)
    end
  end
end

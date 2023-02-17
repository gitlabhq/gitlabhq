# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Database, feature_category: :database do
  let(:database_name) { 'main' }
  let(:database_indexes) do
    [['index', 'CREATE UNIQUE INDEX "index" ON public.achievements USING btree (namespace_id, lower(name))']]
  end

  let(:query_result) { instance_double('ActiveRecord::Result', rows: database_indexes) }
  let(:database_model) { Gitlab::Database.database_base_models[database_name] }
  let(:connection) { database_model.connection }

  subject(:database) { described_class.new(connection) }

  before do
    allow(connection).to receive(:exec_query).and_return(query_result)
  end

  describe '#fetch_index_by_name' do
    context 'when index does not exist' do
      it 'returns nil' do
        index = database.fetch_index_by_name('non_existing_index')

        expect(index).to be_nil
      end
    end

    it 'returns index by name' do
      index = database.fetch_index_by_name('index')

      expect(index.name).to eq('index')
    end
  end

  describe '#index_exists?' do
    context 'when index exists' do
      it 'returns true' do
        index_exists = database.index_exists?('index')

        expect(index_exists).to be_truthy
      end
    end

    context 'when index does not exist' do
      it 'returns false' do
        index_exists = database.index_exists?('non_existing_index')

        expect(index_exists).to be_falsey
      end
    end
  end

  describe '#indexes' do
    it 'returns indexes' do
      indexes = database.indexes

      expect(indexes).to all(be_a(Gitlab::Database::SchemaValidation::Index))
      expect(indexes.map(&:name)).to eq(['index'])
    end
  end
end

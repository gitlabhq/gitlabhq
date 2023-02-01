# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Indexes, feature_category: :database do
  let(:structure_file_path) { Rails.root.join('spec/fixtures/structure.sql') }
  let(:database_indexes) do
    [
      ['wrong_index', 'CREATE UNIQUE INDEX public.wrong_index ON table_name (column_name)'],
      ['extra_index', 'CREATE INDEX public.extra_index ON table_name (column_name)'],
      ['index', 'CREATE UNIQUE INDEX "index" ON public.achievements USING btree (namespace_id, lower(name))']
    ]
  end

  let(:database_name) { 'main' }

  let(:database_model) { Gitlab::Database.database_base_models[database_name] }

  let(:connection) { database_model.connection }

  let(:query_result) { instance_double('ActiveRecord::Result', rows: database_indexes) }

  subject(:schema_validation) { described_class.new(structure_file_path, database_name) }

  before do
    allow(connection).to receive(:exec_query).and_return(query_result)
  end

  describe '#missing_indexes' do
    it 'returns missing indexes' do
      missing_indexes = %w[
        missing_index
        index_namespaces_public_groups_name_id
        index_on_deploy_keys_id_and_type_and_public
        index_users_on_public_email_excluding_null_and_empty
      ]

      expect(schema_validation.missing_indexes).to match_array(missing_indexes)
    end
  end

  describe '#extra_indexes' do
    it 'returns extra indexes' do
      expect(schema_validation.extra_indexes).to match_array(['extra_index'])
    end
  end

  describe '#wrong_indexes' do
    it 'returns wrong indexes' do
      expect(schema_validation.wrong_indexes).to match_array(['wrong_index'])
    end
  end
end

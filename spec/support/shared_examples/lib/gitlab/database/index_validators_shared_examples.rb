# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "index validators" do |validator, expected_result|
  let(:structure_file_path) { Rails.root.join('spec/fixtures/structure.sql') }
  let(:database_indexes) do
    [
      ['wrong_index', 'CREATE UNIQUE INDEX wrong_index ON public.table_name (column_name)'],
      ['extra_index', 'CREATE INDEX extra_index ON public.table_name (column_name)'],
      ['index', 'CREATE UNIQUE INDEX "index" ON public.achievements USING btree (namespace_id, lower(name))']
    ]
  end

  let(:inconsistency_type) { validator.name.demodulize.underscore }

  let(:database_name) { 'main' }

  let(:database_model) { Gitlab::Database.database_base_models[database_name] }

  let(:connection) { database_model.connection }

  let(:query_result) { instance_double('ActiveRecord::Result', rows: database_indexes) }

  let(:database) { Gitlab::Database::SchemaValidation::Database.new(connection) }
  let(:structure_file) { Gitlab::Database::SchemaValidation::StructureSql.new(structure_file_path) }

  subject(:result) { validator.new(structure_file, database).execute }

  before do
    allow(connection).to receive(:exec_query).and_return(query_result)
  end

  it 'returns index inconsistencies' do
    expect(result.map(&:object_name)).to match_array(expected_result)
    expect(result.map(&:type)).to all(eql inconsistency_type)
  end
end

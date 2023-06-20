# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'foreign key validators' do |validator, expected_result|
  subject(:result) { validator.new(structure_file, database).execute }

  let(:structure_file_path) { Rails.root.join('spec/fixtures/structure.sql') }
  let(:structure_file) { Gitlab::Database::SchemaValidation::StructureSql.new(structure_file_path, schema) }
  let(:inconsistency_type) { validator.name.demodulize.underscore }
  let(:database_name) { 'main' }
  let(:schema) { 'public' }
  let(:database_model) { Gitlab::Database.database_base_models[database_name] }
  let(:connection) { database_model.connection }
  let(:database) { Gitlab::Database::SchemaValidation::Database.new(connection) }

  let(:database_query) do
    [
      {
        'schema' => schema,
        'table_name' => 'web_hooks',
        'foreign_key_name' => 'web_hooks_project_id_fkey',
        'foreign_key_definition' => 'FOREIGN KEY (project_id) REFERENCES projects(id) ON DELETE CASCADE'
      },
      {
        'schema' => schema,
        'table_name' => 'issues',
        'foreign_key_name' => 'wrong_definition_fk',
        'foreign_key_definition' => 'FOREIGN KEY (author_id) REFERENCES users(id) ON DELETE CASCADE'
      },
      {
        'schema' => schema,
        'table_name' => 'projects',
        'foreign_key_name' => 'extra_fk',
        'foreign_key_definition' => 'FOREIGN KEY (creator_id) REFERENCES users(id) ON DELETE CASCADE'
      }
    ]
  end

  before do
    allow(connection).to receive(:exec_query).and_return(database_query)
  end

  it 'returns trigger inconsistencies' do
    expect(result.map(&:object_name)).to match_array(expected_result)
    expect(result.map(&:type)).to all(eql inconsistency_type)
  end
end

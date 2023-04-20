# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples "table validators" do |validator, expected_result|
  subject(:result) { validator.new(structure_file, database).execute }

  let(:structure_file_path) { Rails.root.join('spec/fixtures/structure.sql') }
  let(:inconsistency_type) { validator.name.demodulize.underscore }
  let(:database_model) { Gitlab::Database.database_base_models['main'] }
  let(:connection) { database_model.connection }
  let(:schema) { connection.current_schema }
  let(:database) { Gitlab::Database::SchemaValidation::Database.new(connection) }
  let(:structure_file) { Gitlab::Database::SchemaValidation::StructureSql.new(structure_file_path, schema) }
  let(:database_tables) do
    [
      {
        'table_name' => 'wrong_table',
        'column_name' => 'id',
        'not_null' => true,
        'data_type' => 'integer',
        'column_default' => "nextval('audit_events_id_seq'::regclass)"
      },
      {
        'table_name' => 'wrong_table',
        'column_name' => 'description',
        'not_null' => true,
        'data_type' => 'character varying',
        'column_default' => nil
      },
      {
        'table_name' => 'extra_table',
        'column_name' => 'id',
        'not_null' => true,
        'data_type' => 'integer',
        'column_default' => "nextval('audit_events_id_seq'::regclass)"
      },
      {
        'table_name' => 'extra_table',
        'column_name' => 'email',
        'not_null' => true,
        'data_type' => 'character varying',
        'column_default' => nil
      },
      {
        'table_name' => 'extra_table_columns',
        'column_name' => 'id',
        'not_null' => true,
        'data_type' => 'bigint',
        'column_default' => "nextval('audit_events_id_seq'::regclass)"
      },
      {
        'table_name' => 'extra_table_columns',
        'column_name' => 'name',
        'not_null' => true,
        'data_type' => 'character varying(255)',
        'column_default' => nil
      },
      {
        'table_name' => 'extra_table_columns',
        'column_name' => 'extra_column',
        'not_null' => true,
        'data_type' => 'character varying(255)',
        'column_default' => nil
      },
      {
        'table_name' => 'missing_table_columns',
        'column_name' => 'id',
        'not_null' => true,
        'data_type' => 'bigint',
        'column_default' => 'NOT NULL'
      }
    ]
  end

  before do
    allow(connection).to receive(:exec_query).and_return(database_tables)
  end

  it 'returns table inconsistencies' do
    expect(result.map(&:object_name)).to match_array(expected_result)
    expect(result.map(&:type)).to all(eql inconsistency_type)
  end
end

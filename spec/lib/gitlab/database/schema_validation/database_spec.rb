# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'database schema assertions for' do |fetch_by_name_method, exists_method, all_objects_method|
  subject(:database) { described_class.new(connection) }

  let(:database_model) { Gitlab::Database.database_base_models['main'] }
  let(:connection) { database_model.connection }

  before do
    allow(connection).to receive(:select_rows).and_return(results)
    allow(connection).to receive(:exec_query).and_return(results)
  end

  describe "##{fetch_by_name_method}" do
    it 'returns nil when schema object does not exists' do
      expect(database.public_send(fetch_by_name_method, 'invalid-object-name')).to be_nil
    end

    it 'returns the schema object by name' do
      expect(database.public_send(fetch_by_name_method, valid_schema_object_name).name).to eq(valid_schema_object_name)
    end
  end

  describe "##{exists_method}" do
    it 'returns true when schema object exists' do
      expect(database.public_send(exists_method, valid_schema_object_name)).to be_truthy
    end

    it 'returns false when schema object does not exists' do
      expect(database.public_send(exists_method, 'invalid-object')).to be_falsey
    end
  end

  describe "##{all_objects_method}" do
    it 'returns all the schema objects' do
      schema_objects = database.public_send(all_objects_method)

      expect(schema_objects).to all(be_a(schema_object))
      expect(schema_objects.map(&:name)).to eq([valid_schema_object_name])
    end
  end
end

RSpec.describe Gitlab::Database::SchemaValidation::Database, feature_category: :database do
  context 'when having indexes' do
    let(:schema_object) { Gitlab::Database::SchemaValidation::SchemaObjects::Index }
    let(:valid_schema_object_name) { 'index' }
    let(:results) do
      [['index', 'CREATE UNIQUE INDEX "index" ON public.achievements USING btree (namespace_id, lower(name))']]
    end

    include_examples 'database schema assertions for', 'fetch_index_by_name', 'index_exists?', 'indexes'
  end

  context 'when having triggers' do
    let(:schema_object) { Gitlab::Database::SchemaValidation::SchemaObjects::Trigger }
    let(:valid_schema_object_name) { 'my_trigger' }
    let(:results) do
      [['my_trigger', 'CREATE TRIGGER my_trigger BEFORE INSERT ON todos FOR EACH ROW EXECUTE FUNCTION trigger()']]
    end

    include_examples 'database schema assertions for', 'fetch_trigger_by_name', 'trigger_exists?', 'triggers'
  end

  context 'when having tables' do
    let(:schema_object) { Gitlab::Database::SchemaValidation::SchemaObjects::Table }
    let(:valid_schema_object_name) { 'my_table' }
    let(:results) do
      [
        {
          'table_name' => 'my_table',
          'column_name' => 'id',
          'not_null' => true,
          'data_type' => 'bigint',
          'partition_key' => false,
          'column_default' => "nextval('audit_events_id_seq'::regclass)"
        },
        {
          'table_name' => 'my_table',
          'column_name' => 'details',
          'not_null' => false,
          'data_type' => 'text',
          'partition_key' => false,
          'column_default' => nil
        }
      ]
    end

    include_examples 'database schema assertions for', 'fetch_table_by_name', 'table_exists?', 'tables'
  end
end

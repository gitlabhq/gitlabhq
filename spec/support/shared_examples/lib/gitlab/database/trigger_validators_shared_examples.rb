# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'trigger validators' do |validator, expected_result|
  subject(:result) { validator.new(structure_file, database).execute }

  let(:structure_file_path) { Rails.root.join('spec/fixtures/structure.sql') }
  let(:structure_file) { Gitlab::Database::SchemaValidation::StructureSql.new(structure_file_path, schema) }
  let(:inconsistency_type) { validator.name.demodulize.underscore }
  let(:database_name) { 'main' }
  let(:schema) { 'public' }
  let(:database_model) { Gitlab::Database.database_base_models[database_name] }
  let(:connection) { database_model.connection }
  let(:database) { Gitlab::Database::SchemaValidation::Database.new(connection) }

  let(:database_triggers) do
    [
      ['trigger', 'CREATE TRIGGER trigger AFTER INSERT ON public.t1 FOR EACH ROW EXECUTE FUNCTION t1()'],
      ['wrong_trigger', 'CREATE TRIGGER wrong_trigger BEFORE UPDATE ON public.t2 FOR EACH ROW EXECUTE FUNCTION t2()'],
      ['extra_trigger', 'CREATE TRIGGER extra_trigger BEFORE INSERT ON public.t4 FOR EACH ROW EXECUTE FUNCTION t4()']
    ]
  end

  before do
    allow(connection).to receive(:select_rows).and_return(database_triggers)
  end

  it 'returns trigger inconsistencies' do
    expect(result.map(&:object_name)).to match_array(expected_result)
    expect(result.map(&:type)).to all(eql inconsistency_type)
  end
end

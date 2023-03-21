# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Runner, feature_category: :database do
  let(:structure_file_path) { Rails.root.join('spec/fixtures/structure.sql') }
  let(:connection) { ActiveRecord::Base.connection }

  let(:database) { Gitlab::Database::SchemaValidation::Database.new(connection) }
  let(:structure_sql) { Gitlab::Database::SchemaValidation::StructureSql.new(structure_file_path, 'public') }

  describe '#execute' do
    subject(:inconsistencies) { described_class.new(structure_sql, database).execute }

    it 'returns inconsistencies' do
      expect(inconsistencies).not_to be_empty
    end

    it 'execute all validators' do
      all_validators = Gitlab::Database::SchemaValidation::Validators::BaseValidator.all_validators

      expect(all_validators).to all(receive(:new).with(structure_sql, database).and_call_original)

      inconsistencies
    end

    context 'when validators are passed' do
      subject(:inconsistencies) { described_class.new(structure_sql, database, validators: validators).execute }

      let(:class_name) { 'Gitlab::Database::SchemaValidation::Validators::ExtraIndexes' }
      let(:inconsistency_class_name) { 'Gitlab::Database::SchemaValidation::Inconsistency' }

      let(:extra_indexes) { class_double(class_name) }
      let(:instace_extra_index) { instance_double(class_name, execute: [inconsistency]) }
      let(:inconsistency) { instance_double(inconsistency_class_name, object_name: 'test') }

      let(:validators) { [extra_indexes] }

      it 'only execute the validators passed' do
        expect(extra_indexes).to receive(:new).with(structure_sql, database).and_return(instace_extra_index)

        Gitlab::Database::SchemaValidation::Validators::BaseValidator.all_validators.each do |validator|
          expect(validator).not_to receive(:new).with(structure_sql, database)
        end

        expect(inconsistencies.map(&:object_name)).to eql ['test']
      end
    end
  end
end

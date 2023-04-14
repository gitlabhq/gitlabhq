# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SchemaValidation::Validators::BaseValidator, feature_category: :database do
  describe '.all_validators' do
    subject(:all_validators) { described_class.all_validators }

    it 'returns an array of all validators' do
      expect(all_validators).to eq([
        Gitlab::Database::SchemaValidation::Validators::ExtraTables,
        Gitlab::Database::SchemaValidation::Validators::ExtraTableColumns,
        Gitlab::Database::SchemaValidation::Validators::ExtraIndexes,
        Gitlab::Database::SchemaValidation::Validators::ExtraTriggers,
        Gitlab::Database::SchemaValidation::Validators::MissingTables,
        Gitlab::Database::SchemaValidation::Validators::MissingTableColumns,
        Gitlab::Database::SchemaValidation::Validators::MissingIndexes,
        Gitlab::Database::SchemaValidation::Validators::MissingTriggers,
        Gitlab::Database::SchemaValidation::Validators::DifferentDefinitionTables,
        Gitlab::Database::SchemaValidation::Validators::DifferentDefinitionIndexes,
        Gitlab::Database::SchemaValidation::Validators::DifferentDefinitionTriggers
      ])
    end
  end

  describe '#execute' do
    let(:structure_sql) { instance_double(Gitlab::Database::SchemaValidation::StructureSql) }
    let(:database) { instance_double(Gitlab::Database::SchemaValidation::Database) }

    subject(:inconsistencies) { described_class.new(structure_sql, database).execute }

    it 'raises an exception' do
      expect { inconsistencies }.to raise_error(NoMethodError)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe RecreateIndexSecurityCiBuildsOnNameAndIdParserWithNewFeatures, :migration, feature_category: :continuous_integration do
  let(:db) { described_class.new }
  let(:pg_class) { table(:pg_class) }
  let(:pg_index) { table(:pg_index) }
  let(:async_indexes) { table(:postgres_async_indexes) }

  it 'recreates index' do
    reversible_migration do |migration|
      migration.before -> {
        expect(async_indexes.where(name: described_class::OLD_INDEX_NAME).exists?).to be false
        expect(db.index_exists?(described_class::TABLE, described_class::COLUMNS, name: described_class::OLD_INDEX_NAME)).to be true
        expect(db.index_exists?(described_class::TABLE, described_class::COLUMNS, name: described_class::NEW_INDEX_NAME)).to be false
      }

      migration.after -> {
        expect(async_indexes.where(name: described_class::OLD_INDEX_NAME).exists?).to be true
        expect(db.index_exists?(described_class::TABLE, described_class::COLUMNS, name: described_class::OLD_INDEX_NAME)).to be false
        expect(db.index_exists?(described_class::TABLE, described_class::COLUMNS, name: described_class::NEW_INDEX_NAME)).to be true
      }
    end
  end
end

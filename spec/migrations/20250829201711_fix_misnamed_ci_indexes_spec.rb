# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixMisnamedCiIndexes, feature_category: :continuous_integration do
  let(:migration) { described_class.new }

  # Table references for the partitioned tables
  let(:ci_builds_metadata) { table(:p_ci_builds_metadata) }
  let(:ci_pipelines) { table(:p_ci_pipelines) }
  let(:ci_stages) { table(:p_ci_stages) }

  describe '#up' do
    before do
      # Create the old indexes that need to be renamed
      described_class::INDEXES_TO_RENAME.each do |table_name, indexes|
        indexes.each do |columns, old_name, new_name|
          next if migration.index_exists?(table_name, columns, name: old_name)

          migration.rename_index(table_name, new_name, old_name)
        end
      end
    end

    it 'renames all misnamed indexes to their correct names' do
      # Sanity check: verify old indexes exist before migration
      described_class::INDEXES_TO_RENAME.each do |table_name, indexes|
        indexes.each do |columns, old_name, _new_name|
          expect(migration.index_exists?(table_name, columns, name: old_name))
            .to be(true), "Expected old index #{old_name} to exist on #{table_name} before migration"
        end
      end

      migrate!

      # Verify all indexes were renamed correctly
      described_class::INDEXES_TO_RENAME.each do |table_name, indexes|
        indexes.each do |columns, old_name, new_name|
          expect(migration.index_exists?(table_name, columns, name: old_name))
            .to be(false), "Expected old index #{old_name} to not exist on #{table_name} after migration"

          expect(migration.index_exists?(table_name, columns, name: new_name))
            .to be(true), "Expected new index #{new_name} to exist on #{table_name} after migration"
        end
      end
    end

    it 'is idempotent and can be run multiple times safely' do
      migrate!

      expect { migrate! }.not_to raise_error

      # Verify indexes are still correctly named
      described_class::INDEXES_TO_RENAME.each do |table_name, indexes|
        indexes.each do |columns, _old_name, new_name|
          expect(migration.index_exists?(table_name, columns, name: new_name))
            .to be(true), "Expected new index #{new_name} to still exist after second migration run"
        end
      end
    end

    it 'skips renaming if the new index already exists' do
      # Create some new indexes manually
      sample_table, sample_indexes = described_class::INDEXES_TO_RENAME.first
      sample_columns, _, sample_new_name = sample_indexes.first

      # Create the new index manually
      migration.add_index(sample_table, sample_columns, name: sample_new_name)

      expect { migrate! }.not_to raise_error

      # Verify the manually created index still exists
      expect(migration.index_exists?(sample_table, sample_columns, name: sample_new_name))
        .to be(true)

      # Drop this newly added index for subsequent tests
      migration.remove_index(sample_table, sample_columns, name: sample_new_name)
    end

    it 'skips renaming if the old index does not exist' do
      # Remove one of the old indexes
      sample_table, sample_indexes = described_class::INDEXES_TO_RENAME.first
      sample_columns, sample_old_name, sample_new_name = sample_indexes.first

      if migration.index_exists?(sample_table, sample_columns, name: sample_old_name)
        migration.remove_index(sample_table, sample_columns, name: sample_old_name)
      end

      expect { migrate! }.not_to raise_error

      # Verify the new index was not created since old one didn't exist
      expect(migration.index_exists?(sample_table, sample_columns, name: sample_new_name))
        .to be(false)
    end
  end
end

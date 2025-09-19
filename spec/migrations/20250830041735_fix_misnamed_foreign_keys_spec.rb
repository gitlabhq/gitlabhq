# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixMisnamedForeignKeys, feature_category: :database do
  let(:migration) { described_class.new }

  describe '#up' do
    before do
      # Ensure old foreign keys exist for testing by reversing any that might already be renamed
      described_class::FOREIGN_KEYS.each do |data|
        table_name = data[:table]
        old_name = data[:old_name]
        new_name = data[:new_name]

        # If the new foreign key exists but old doesn't, rename it back for testing
        if migration.foreign_key_exists?(table_name, name: new_name) &&
            !migration.foreign_key_exists?(table_name, name: old_name)
          migration.rename_constraint(table_name, new_name, old_name)
        end
      end
    end

    it 'renames all misnamed foreign keys to their correct names' do
      migrate!

      # Verify all foreign keys were renamed correctly
      described_class::FOREIGN_KEYS.each do |data|
        table_name = data[:table]
        old_name = data[:old_name]
        new_name = data[:new_name]

        expect(migration.foreign_key_exists?(table_name, name: old_name))
          .to be(false), "Expected old foreign key #{old_name} to not exist on #{table_name} after migration"
        expect(migration.foreign_key_exists?(table_name, name: new_name))
          .to be(true), "Expected new foreign key #{new_name} to exist on #{table_name} after migration"
      end
    end

    it 'is idempotent and can be run multiple times safely' do
      migrate!
      expect { migrate! }.not_to raise_error

      # Verify foreign keys are still correctly named after second run
      described_class::FOREIGN_KEYS.each do |data|
        table_name = data[:table]
        new_name = data[:new_name]

        expect(migration.foreign_key_exists?(table_name, name: new_name))
          .to be(true), "Expected new foreign key #{new_name} to still exist after second migration run"
      end
    end

    it 'skips renaming if the new foreign key already exists' do
      # Pre-rename one foreign key to simulate already having the correct name
      sample_data = described_class::FOREIGN_KEYS.first
      sample_table = sample_data[:table]
      sample_old_name = sample_data[:old_name]
      sample_new_name = sample_data[:new_name]

      if migration.foreign_key_exists?(sample_table, name: sample_old_name)
        migration.rename_constraint(sample_table, sample_old_name, sample_new_name)
      end

      expect { migrate! }.not_to raise_error

      # Verify the pre-renamed foreign key still exists with correct name
      expect(migration.foreign_key_exists?(sample_table, name: sample_new_name))
        .to be(true)
    end

    it 'skips renaming if the old foreign key does not exist' do
      # Remove one of the old foreign keys to simulate it not existing
      sample_data = described_class::FOREIGN_KEYS.first
      sample_table = sample_data[:table]
      sample_old_name = sample_data[:old_name]
      sample_new_name = sample_data[:new_name]
      temporary_name = "#{sample_old_name}_tmp"

      migration.rename_constraint(sample_table, sample_old_name, temporary_name)

      expect { migrate! }.not_to raise_error

      expect(migration.foreign_key_exists?(sample_table, sample_new_name))
        .to be(false)

      migration.rename_constraint(sample_table, temporary_name, sample_new_name)
    end
  end

  describe '#down' do
    it 'is intentionally empty and irreversible' do
      expect(described_class.new.method(:down).source_location).to be_present
      # The down method should be empty as foreign key names don't affect functionality
      expect { described_class.new.down }.not_to raise_error
    end
  end
end

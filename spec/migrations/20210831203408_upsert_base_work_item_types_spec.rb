# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpsertBaseWorkItemTypes, :migration do
  let!(:work_item_types) { table(:work_item_types) }

  after(:all) do
    # Make sure base types are recreated after running the migration
    # because migration specs are not run in a transaction
    WorkItem::Type.delete_all
    Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.import
  end

  context 'when no default types exist' do
    it 'creates default data' do
      # Need to delete all as base types are seeded before entire test suite
      WorkItem::Type.delete_all

      expect(work_item_types.count).to eq(0)

      reversible_migration do |migration|
        migration.before -> {
          # Depending on whether the migration has been run before,
          # the size could be 4, or 0, so we don't set any expectations
          # as we don't delete base types on migration reverse
        }

        migration.after -> {
          expect(work_item_types.count).to eq(4)
          expect(work_item_types.all.pluck(:base_type)).to match_array(WorkItem::Type.base_types.values)
        }
      end
    end
  end

  context 'when default types already exist' do
    it 'does not create default types again' do
      expect(work_item_types.all.pluck(:base_type)).to match_array(WorkItem::Type.base_types.values)

      reversible_migration do |migration|
        migration.before -> {
          expect(work_item_types.all.pluck(:base_type)).to match_array(WorkItem::Type.base_types.values)
        }

        migration.after -> {
          expect(work_item_types.count).to eq(4)
          expect(work_item_types.all.pluck(:base_type)).to match_array(WorkItem::Type.base_types.values)
        }
      end
    end
  end
end

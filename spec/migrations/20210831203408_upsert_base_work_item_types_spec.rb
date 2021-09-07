# frozen_string_literal: true

require 'spec_helper'
require_migration!('upsert_base_work_item_types')

RSpec.describe UpsertBaseWorkItemTypes, :migration do
  let!(:work_item_types) { table(:work_item_types) }

  context 'when no default types exist' do
    it 'creates default data' do
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
    before do
      Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.import
    end

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

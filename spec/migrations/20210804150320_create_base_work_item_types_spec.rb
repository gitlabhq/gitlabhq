# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CreateBaseWorkItemTypes, :migration do
  let!(:work_item_types) { table(:work_item_types) }

  after(:all) do
    # Make sure base types are recreated after running the migration
    # because migration specs are not run in a transaction
    WorkItem::Type.delete_all
    Gitlab::DatabaseImporters::WorkItems::BaseTypeImporter.import
  end

  it 'creates default data' do
    # Need to delete all as base types are seeded before entire test suite
    WorkItem::Type.delete_all

    reversible_migration do |migration|
      migration.before -> {
        # Depending on whether the migration has been run before,
        # the size could be 4, or 0, so we don't set any expectations
      }

      migration.after -> {
        expect(work_item_types.count).to eq 4
        expect(work_item_types.all.pluck(:base_type)).to match_array WorkItem::Type.base_types.values
      }
    end
  end
end

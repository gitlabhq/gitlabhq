# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddOkrHierarchyRestrictions, :migration, feature_category: :portfolio_management do
  include MigrationHelpers::WorkItemTypesHelper

  let!(:restrictions) { table(:work_item_hierarchy_restrictions) }
  let!(:work_item_types) { table(:work_item_types) }

  it 'creates default restrictions' do
    restrictions.delete_all

    reversible_migration do |migration|
      migration.before -> {
        expect(restrictions.count).to eq(0)
      }

      migration.after -> {
        expect(restrictions.count).to eq(4)
      }
    end
  end

  context 'when work items are missing' do
    before do
      work_item_types.delete_all
    end

    it 'does nothing' do
      expect { migrate! }.not_to change { restrictions.count }
    end
  end
end

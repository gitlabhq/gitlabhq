# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddWorkItemsRelatedLinkRestrictions, :migration, feature_category: :portfolio_management do
  let!(:restrictions) { table(:work_item_related_link_restrictions) }
  let!(:work_item_types) { table(:work_item_types) }

  # These rules are documented in https://docs.gitlab.com/ee/development/work_items.html#write-a-database-migration
  it 'creates default restrictions' do
    restrictions.delete_all

    reversible_migration do |migration|
      migration.before -> {
        expect(restrictions.count).to eq(0)
      }

      migration.after -> {
        expect(restrictions.count).to eq(34)
      }
    end
  end

  context 'when work item types are missing' do
    before do
      work_item_types.delete_all
    end

    it 'does not add restrictions' do
      expect(Gitlab::AppLogger).to receive(:warn)
        .with('Default WorkItemType records are missing, not adding RelatedLinkRestrictions.')

      expect { migrate! }.not_to change { restrictions.count }
    end
  end
end

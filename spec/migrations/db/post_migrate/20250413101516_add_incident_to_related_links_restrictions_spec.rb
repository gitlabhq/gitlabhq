# frozen_string_literal: true

require 'spec_helper'
require_migration!

TOTAL_RESTRICTIONS = 51
SOURCE_INCIDENT_RESTRICTIONS = 7
TARGET_INCIDENT_RESTRICTIONS = 12
PRE_MIGRATION_RESTRICTIONS = 34

RSpec.describe AddIncidentToRelatedLinksRestrictions, feature_category: :database, migration_version: 20250310182907 do
  let(:migration) { described_class.new }
  let(:work_item_types) { table(:work_item_types) }
  let(:related_link_restrictions) { table(:work_item_related_link_restrictions) }

  let(:base_types) do
    {
      issue: 0,
      incident: 1,
      task: 4,
      objective: 5,
      key_result: 6,
      epic: 7
    }
  end

  let(:work_item_type_ids) do
    base_types.transform_values { |base_type| work_item_types.find_by!(base_type: base_type).id }
  end

  describe '#up' do
    it 'creates related link restrictions for incidents' do
      migration.up

      expect(related_link_restrictions.count).to eq(TOTAL_RESTRICTIONS)

      expect(
        related_link_restrictions.exists?(
          source_type_id: work_item_type_ids[:issue],
          target_type_id: work_item_type_ids[:incident],
          link_type: 0
        )
      ).to be_truthy

      expect(
        related_link_restrictions.where(source_type_id: work_item_type_ids[:incident]).count
      ).to eq(SOURCE_INCIDENT_RESTRICTIONS)

      expect(
        related_link_restrictions.where(target_type_id: work_item_type_ids[:incident]).count
      ).to eq(TARGET_INCIDENT_RESTRICTIONS)
    end
  end

  describe '#down' do
    before do
      migration.up
    end

    it 'removes all incident-related restrictions' do
      expect(related_link_restrictions.count).to eq(TOTAL_RESTRICTIONS)

      migration.down

      expect(related_link_restrictions.count).to eq(PRE_MIGRATION_RESTRICTIONS)

      expect(
        related_link_restrictions.where(source_type_id: work_item_type_ids[:incident]).count
      ).to eq(0)

      expect(
        related_link_restrictions.where(target_type_id: work_item_type_ids[:incident]).count
      ).to eq(0)

      expect(
        related_link_restrictions.exists?(
          source_type_id: work_item_type_ids[:incident],
          target_type_id: work_item_type_ids[:issue],
          link_type: 0
        )
      ).to be_falsey
    end
  end
end

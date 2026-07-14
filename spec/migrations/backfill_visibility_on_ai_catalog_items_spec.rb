# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillVisibilityOnAiCatalogItems, feature_category: :workflow_catalog do
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:organizations) { table(:organizations) }

  let!(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }

  let!(:public_item) do
    ai_catalog_items.create!(
      organization_id: organization.id,
      item_type: 0,
      name: 'Public Agent',
      description: 'A public agent',
      public: true,
      visibility: 0
    )
  end

  let!(:private_item) do
    ai_catalog_items.create!(
      organization_id: organization.id,
      item_type: 0,
      name: 'Private Agent',
      description: 'A private agent',
      public: false,
      visibility: 0
    )
  end

  describe '#up' do
    it 'backfills visibility from public column', :aggregate_failures do
      migrate!

      expect(public_item.reload.visibility).to eq(2)
      expect(private_item.reload.visibility).to eq(0)
    end
  end

  describe '#down' do
    it 'resets visibility to private', :aggregate_failures do
      migrate!
      schema_migrate_down!

      expect(public_item.reload.visibility).to eq(0)
      expect(private_item.reload.visibility).to eq(0)
    end
  end
end

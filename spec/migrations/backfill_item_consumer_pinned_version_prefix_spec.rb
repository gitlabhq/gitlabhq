# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillItemConsumerPinnedVersionPrefix, feature_category: :workflow_catalog do
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_versions) { table(:ai_catalog_item_versions) }
  let(:ai_catalog_item_consumers) { table(:ai_catalog_item_consumers) }
  let(:organizations) { table(:organizations) }

  let!(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }
  let!(:item1) do
    ai_catalog_items.create!(organization_id: organization.id, name: 'Test Item 1', description: 'Description',
      item_type: 0)
  end

  let!(:item2) do
    ai_catalog_items.create!(organization_id: organization.id, name: 'Test Item 2', description: 'Description',
      item_type: 0)
  end

  let!(:item1_version_old) do
    ai_catalog_item_versions.create!(
      ai_catalog_item_id: item1.id,
      organization_id: organization.id,
      version: '1.0.0',
      schema_version: 1,
      definition: {},
      created_at: 2.days.ago
    )
  end

  let!(:item1_version_latest) do
    ai_catalog_item_versions.create!(
      ai_catalog_item_id: item1.id,
      organization_id: organization.id,
      version: '2.5.0',
      schema_version: 1,
      definition: {},
      created_at: 1.day.ago
    )
  end

  let!(:item2_version) do
    ai_catalog_item_versions.create!(
      ai_catalog_item_id: item2.id,
      organization_id: organization.id,
      version: '3.1.0',
      schema_version: 1,
      definition: {},
      created_at: 1.day.ago
    )
  end

  let!(:consumer1_with_null_prefix) do
    ai_catalog_item_consumers.create!(
      ai_catalog_item_id: item1.id,
      organization_id: organization.id,
      pinned_version_prefix: nil,
      enabled: false,
      locked: true
    )
  end

  let!(:consumer2_with_null_prefix) do
    ai_catalog_item_consumers.create!(
      ai_catalog_item_id: item2.id,
      organization_id: organization.id,
      pinned_version_prefix: nil,
      enabled: false,
      locked: true
    )
  end

  let!(:consumer_with_existing_prefix) do
    ai_catalog_item_consumers.create!(
      ai_catalog_item_id: item1.id,
      organization_id: organization.id,
      pinned_version_prefix: '1.5.0',
      enabled: false,
      locked: true
    )
  end

  it 'updates records with null pinned_version_prefix to their latest item version' do
    migrate!

    expect(consumer1_with_null_prefix.reload.pinned_version_prefix).to eq('2.5.0')
    expect(consumer2_with_null_prefix.reload.pinned_version_prefix).to eq('3.1.0')
    expect(consumer_with_existing_prefix.reload.pinned_version_prefix).to eq('1.5.0')
  end
end

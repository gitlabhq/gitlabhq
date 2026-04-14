# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteAiCatalogItemConsumersWithOrganizationId, feature_category: :workflow_catalog do
  let(:migration) { described_class.new }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:ai_catalog_item_consumers) { table(:ai_catalog_item_consumers) }

  let!(:organization) { organizations.create!(name: 'Test Org', path: 'test-org') }

  let!(:namespace) do
    namespaces.create!(name: 'test-group', path: 'test-group', type: 'Group', organization_id: organization.id)
  end

  let!(:project) do
    projects.create!(
      name: 'test-project',
      path: 'test-project',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:catalog_item) do
    ai_catalog_items.create!(
      organization_id: organization.id,
      item_type: 1,
      description: 'Test item',
      name: 'test-item'
    )
  end

  let!(:org_consumer) do
    ai_catalog_item_consumers.create!(
      ai_catalog_item_id: catalog_item.id,
      organization_id: organization.id
    )
  end

  let!(:group_consumer) do
    ai_catalog_item_consumers.create!(
      ai_catalog_item_id: catalog_item.id,
      group_id: namespace.id
    )
  end

  let!(:project_consumer) do
    ai_catalog_item_consumers.create!(
      ai_catalog_item_id: catalog_item.id,
      project_id: project.id
    )
  end

  describe '#up' do
    it 'deletes only consumers with organization_id set' do
      expect { migration.up }.to change { ai_catalog_item_consumers.count }.from(3).to(2)

      expect(ai_catalog_item_consumers.where(id: org_consumer.id)).to be_empty
      expect(ai_catalog_item_consumers.where(id: group_consumer.id)).not_to be_empty
      expect(ai_catalog_item_consumers.where(id: project_consumer.id)).not_to be_empty
    end
  end
end

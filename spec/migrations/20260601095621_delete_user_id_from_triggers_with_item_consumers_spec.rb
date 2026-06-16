# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteUserIdFromTriggersWithItemConsumers, feature_category: :workflow_catalog do
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:organizations) { table(:organizations) }
  let(:ai_flow_triggers) { table(:ai_flow_triggers) }
  let(:ai_catalog_item_consumers) { table(:ai_catalog_item_consumers) }
  let(:ai_catalog_items) { table(:ai_catalog_items) }
  let(:users) { table(:users) }

  let!(:organization) { organizations.create!(name: 'Organization 1', path: 'organization-1') }
  let!(:namespace) { namespaces.create!(name: 'namespace', path: 'namespace', organization_id: organization.id) }
  let!(:project) do
    projects.create!(name: 'project', namespace_id: namespace.id, project_namespace_id: namespace.id,
      organization_id: organization.id)
  end

  let!(:ai_catalog_item) do
    ai_catalog_items.create!(
      name: 'Test Item',
      description: 'A test AI catalog item',
      public: true,
      project_id: project.id,
      organization_id: organization.id,
      item_type: 0
    )
  end

  let!(:ai_catalog_item_consumer) do
    ai_catalog_item_consumers.create!(ai_catalog_item_id: ai_catalog_item.id, project_id: project.id)
  end

  let!(:user) do
    users.create!(email: 'test@gitlab.com', username: 'test', projects_limit: 10, organization_id: organization.id)
  end

  let!(:ai_flow_trigger_with_both) do
    ai_flow_triggers.create!(
      ai_catalog_item_consumer_id: ai_catalog_item_consumer.id,
      user_id: user.id,
      project_id: project.id,
      description: 'Described'
    )
  end

  let!(:ai_flow_trigger_with_only_user) do
    ai_flow_triggers.create!(
      user_id: user.id,
      project_id: project.id,
      description: 'Described'
    )
  end

  it 'deletes the user_id from the trigger with a catalog item consumer', :aggregate_failures do
    migrate!

    expect(ai_flow_trigger_with_both.reload.user_id).to be_nil
    expect(ai_flow_trigger_with_only_user.reload.user_id).to eq(user.id)
  end
end

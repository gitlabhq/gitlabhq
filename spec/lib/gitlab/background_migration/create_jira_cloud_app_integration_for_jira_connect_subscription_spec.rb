# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::CreateJiraCloudAppIntegrationForJiraConnectSubscription, :sidekiq_inline, feature_category: :integrations do
  let(:jira_connect_installation) { table(:jira_connect_installations) }
  let(:jira_connect_subscriptions) { table(:jira_connect_subscriptions) }

  let(:organizations) { table(:organizations) }
  let(:projects) { table(:projects) }
  let(:namespaces) { table(:namespaces) }
  let(:integrations) { table(:integrations) }

  let(:migration_attrs) do
    {
      start_id: jira_connect_subscriptions.minimum(:id),
      end_id: jira_connect_subscriptions.maximum(:id),
      batch_table: :jira_connect_subscriptions,
      batch_column: :id,
      sub_batch_size: 2,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let!(:organization) { organizations.create!(name: 'organization', path: 'organization') }

  let!(:group_namespace1) do
    namespaces.create!(
      organization_id: organization.id,
      name: 'gitlab-1',
      path: 'gitlab-1',
      type: 'Group'
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:group_namespace1_subgroup) do
    namespaces.create!(
      organization_id: organization.id,
      name: 'gitlab-subgroup',
      path: 'gitlab-subgroup',
      type: 'Group',
      parent_id: group_namespace1.id
    ).tap { |namespace| namespace.update!(traversal_ids: [group_namespace1.id]) }
  end

  let!(:group_namespace2) do
    namespaces.create!(
      organization_id: organization.id,
      name: 'gitlab-2',
      path: 'gitlab-2',
      type: 'Group'
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:group_namespace3) do
    namespaces.create!(
      organization_id: organization.id,
      name: 'gitlab-3',
      path: 'gitlab-3',
      type: 'Group'
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:group_namespace4) do
    namespaces.create!(
      organization_id: organization.id,
      name: 'gitlab-4',
      path: 'gitlab-4',
      type: 'Group'
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:installation) { jira_connect_installation.create! }

  let!(:subscription1) do
    jira_connect_subscriptions.create!(jira_connect_installation_id: installation.id,
      namespace_id: group_namespace1.id, created_at: '2024-06-12 11:14:18.04428',
      updated_at: '2024-06-12 11:14:18.04428')
  end

  let!(:subscription2) do
    jira_connect_subscriptions.create!(jira_connect_installation_id: installation.id,
      namespace_id: group_namespace2.id, created_at: '2024-06-12 11:14:18.04428',
      updated_at: '2024-06-12 11:14:18.04428')
  end

  let!(:subscription3) do
    jira_connect_subscriptions.create!(jira_connect_installation_id: installation.id,
      namespace_id: group_namespace4.id, created_at: '2024-06-12 11:14:18.04428',
      updated_at: '2024-06-12 11:14:18.04428')
  end

  subject(:perform_migration) { described_class.new(**migration_attrs).perform }

  before do
    o = [('a'..'z'), ('A'..'Z')].flat_map(&:to_a)
    13.times do
      project_name = (0...10).map { o[rand(o.length)] }.join
      create_project(project_name, group_namespace1)
    end
    5.times do
      project_name = (0...10).map { o[rand(o.length)] }.join
      create_project(project_name, group_namespace2)
    end
    3.times do
      project_name = (0...10).map { o[rand(o.length)] }.join
      create_project(project_name, group_namespace3)
    end
    4.times do
      project_name = (0...10).map { o[rand(o.length)] }.join
      create_project(project_name, group_namespace4)
    end

    stub_const("#{described_class}::PROJECT_BATCH_SIZE", 5)
  end

  it 'creates jira_cloud_app integration for the groups and descendant projects', :aggregate_failures do
    expect do
      perform_migration
    end.to change { Integration.count }.by(26) # 4 integrations for groups + 22 integrations for projects

    expect(integrations.where(group_id: group_namespace1.id).count).to eq(1)
    expect(integrations.where(group_id: group_namespace2.id).count).to eq(1)
    expect(integrations.where(group_id: group_namespace4.id).count).to eq(1)
    expect(integrations.where(group_id: group_namespace3.id).count).to eq(0)
    expect(integrations.where(group_id: group_namespace1_subgroup.id).count).to eq(1)
  end

  def create_project(name, group)
    project_namespace = namespaces.create!(
      organization_id: organization.id,
      name: name,
      path: name,
      type: 'Project'
    )

    projects.create!(
      organization_id: organization.id,
      namespace_id: group.id,
      project_namespace_id: project_namespace.id,
      name: name,
      path: name
    )
  end
end

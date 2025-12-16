# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillSlackIntegrationsShardingKey, feature_category: :integrations do
  let(:organizations) { table(:organizations) }
  let(:users) { table(:users) }
  let(:integrations) { table(:integrations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:slack_integrations) { table(:slack_integrations) }

  let(:start_id) { slack_integrations.minimum(:id) }
  let(:end_id) { slack_integrations.maximum(:id) }

  let!(:organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:group) { namespaces.create!(name: 'bar', path: 'bar', type: 'Group', organization_id: 1) }
  let!(:user) { users.create!(organization_id: 1, email: 'user@example.com', username: 'user', projects_limit: 10) }

  let!(:project) do
    projects.create!(
      name: 'baz',
      path: 'baz',
      organization_id: 1,
      namespace_id: group.id,
      project_namespace_id: group.id
    )
  end

  let!(:another_project_namespace) do
    namespaces.create!(name: 'another_namespace', path: 'another_namespace', organization_id: 1)
  end

  let!(:another_project) do
    projects.create!(
      name: 'another',
      path: 'another',
      organization_id: 1,
      namespace_id: another_project_namespace.id,
      project_namespace_id: another_project_namespace.id
    )
  end

  let!(:organization_integration) do
    integrations.create!(
      instance: true,
      organization_id: organization.id,
      type_new: 'Integrations::GitlabSlackApplication'
    )
  end

  let!(:org_slack_integration) do
    slack_integrations.create!(
      user_id: user.id,
      integration_id: organization_integration.id,
      team_id: 'ORG123',
      team_name: 'GitLab Organization',
      alias: '_gitlab-instance'
    )
  end

  let!(:group_integration) do
    integrations.create!(
      group_id: group.id,
      type_new: 'Integrations::GitlabSlackApplication'
    )
  end

  let!(:group_slack_integration) do
    slack_integrations.create!(
      user_id: user.id,
      integration_id: group_integration.id,
      team_id: 'GRP123',
      team_name: 'GitLab Group',
      alias: group.path
    )
  end

  let!(:project_integration) do
    integrations.create!(
      project_id: project.id,
      type_new: 'Integrations::GitlabSlackApplication'
    )
  end

  let!(:project_slack_integration) do
    slack_integrations.create!(
      user_id: user.id,
      integration_id: project_integration.id,
      team_id: 'ABC123',
      team_name: 'GitLab Project',
      alias: project.path
    )
  end

  let!(:another_project_integration) do
    integrations.create!(
      project_id: another_project.id,
      type_new: 'Integrations::GitlabSlackApplication'
    )
  end

  let!(:another_project_slack_integration) do
    slack_integrations.create!(
      user_id: user.id,
      integration_id: another_project_integration.id,
      project_id: another_project.id,
      team_id: 'PRJ123',
      team_name: 'GitLab Project',
      alias: another_project.path
    )
  end

  subject(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :slack_integrations,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe "#perform" do
    it 'sets slack_integrations sharding key for records that do not have it' do
      expect(org_slack_integration.project_id).to be_nil
      expect(org_slack_integration.group_id).to be_nil
      expect(org_slack_integration.organization_id).to be_nil

      expect(group_slack_integration.project_id).to be_nil
      expect(group_slack_integration.group_id).to be_nil
      expect(group_slack_integration.organization_id).to be_nil

      expect(project_slack_integration.project_id).to be_nil
      expect(project_slack_integration.group_id).to be_nil
      expect(project_slack_integration.organization_id).to be_nil

      expect(another_project_slack_integration.project_id).to eq(another_project.id)
      expect(another_project_slack_integration.group_id).to be_nil
      expect(another_project_slack_integration.organization_id).to be_nil

      migration.perform

      expect(org_slack_integration.reload.project_id).to be_nil
      expect(org_slack_integration.group_id).to be_nil
      expect(org_slack_integration.organization_id).to eq(organization.id)

      expect(group_slack_integration.reload.project_id).to be_nil
      expect(group_slack_integration.group_id).to eq(group.id)
      expect(group_slack_integration.organization_id).to be_nil

      expect(project_slack_integration.reload.project_id).to eq(project.id)
      expect(project_slack_integration.group_id).to be_nil
      expect(project_slack_integration.organization_id).to be_nil

      expect(another_project_slack_integration.reload.project_id).to eq(another_project.id)
      expect(another_project_slack_integration.group_id).to be_nil
      expect(another_project_slack_integration.organization_id).to be_nil
    end
  end
end

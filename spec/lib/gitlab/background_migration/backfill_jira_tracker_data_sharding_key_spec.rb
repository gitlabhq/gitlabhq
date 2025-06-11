# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillJiraTrackerDataShardingKey, feature_category: :integrations do
  let(:organizations) { table(:organizations) }
  let(:integrations) { table(:integrations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:jira_tracker_data) { table(:jira_tracker_data) }
  let(:start_id) { jira_tracker_data.minimum(:id) }
  let(:end_id) { jira_tracker_data.maximum(:id) }

  let!(:organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:group) { namespaces.create!(name: 'bar', path: 'bar', type: 'Group', organization_id: 1) }

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
    integrations.create!(instance: true, organization_id: organization.id, type_new: 'Integrations::Bugzilla')
  end

  let!(:org_tracker_data) do
    jira_tracker_data.create!(integration_id: organization_integration.id)
  end

  let!(:group_integration) do
    integrations.create!(group_id: group.id, type_new: 'Integrations::Redmine')
  end

  let!(:group_tracker_data) do
    jira_tracker_data.create!(integration_id: group_integration.id)
  end

  let!(:project_integration) do
    integrations.create!(project_id: project.id, type_new: 'Integrations::Youtrack')
  end

  let!(:project_tracker_data) do
    jira_tracker_data.create!(integration_id: project_integration.id)
  end

  let!(:another_project_integration) do
    integrations.create!(project_id: another_project.id, type_new: 'Integrations::Clickup')
  end

  let!(:another_project_tracker_data) do
    jira_tracker_data.create!(integration_id: another_project_integration.id, project_id: another_project.id)
  end

  subject(:migration) do
    described_class.new(
      start_id: start_id,
      end_id: end_id,
      batch_table: :jira_tracker_data,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    )
  end

  describe "#perform" do
    it 'sets jira_tracker_data sharding key for records that do not have it' do
      expect(org_tracker_data.project_id).to be_nil
      expect(org_tracker_data.group_id).to be_nil
      expect(org_tracker_data.organization_id).to be_nil

      expect(group_tracker_data.project_id).to be_nil
      expect(group_tracker_data.group_id).to be_nil
      expect(group_tracker_data.organization_id).to be_nil

      expect(project_tracker_data.project_id).to be_nil
      expect(project_tracker_data.group_id).to be_nil
      expect(project_tracker_data.organization_id).to be_nil

      expect(another_project_tracker_data.project_id).to eq(another_project.id)
      expect(another_project_tracker_data.group_id).to be_nil
      expect(another_project_tracker_data.organization_id).to be_nil

      migration.perform

      expect(org_tracker_data.reload.project_id).to be_nil
      expect(org_tracker_data.reload.group_id).to be_nil
      expect(org_tracker_data.reload.organization_id).to eq(organization.id)

      expect(group_tracker_data.reload.project_id).to be_nil
      expect(group_tracker_data.reload.group_id).to eq(group.id)
      expect(group_tracker_data.reload.organization_id).to be_nil

      expect(project_tracker_data.reload.project_id).to eq(project.id)
      expect(project_tracker_data.reload.group_id).to be_nil
      expect(project_tracker_data.reload.organization_id).to be_nil

      expect(another_project_tracker_data.reload.project_id).to eq(another_project.id)
      expect(another_project_tracker_data.reload.group_id).to be_nil
      expect(another_project_tracker_data.reload.organization_id).to be_nil
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillJiraTrackerDataNullShardingKey, feature_category: :integrations do
  let(:organizations) { table(:organizations) }
  let(:jira_tracker_data) { table(:jira_tracker_data) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:integrations) { table(:integrations) }

  let!(:organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:group) { namespaces.create!(name: 'bar', path: 'bar', type: 'Group', organization_id: 1) }
  let!(:another_group) { namespaces.create!(name: 'bar', path: 'bar', type: 'Group', organization_id: 1) }

  let!(:project) do
    projects.create!(
      name: 'baz',
      path: 'baz',
      organization_id: 1,
      namespace_id: group.id,
      project_namespace_id: group.id
    )
  end

  let!(:group_integration) do
    integrations.create!(group_id: group.id, type_new: 'Integrations::Jira')
  end

  let!(:another_group_integration) do
    integrations.create!(group_id: another_group.id, type_new: 'Integrations::Jira')
  end

  let!(:project_integration) do
    integrations.create!(project_id: project.id, type_new: 'Integrations::Jira')
  end

  let!(:organization_integration) do
    integrations.create!(organization_id: organization.id, type_new: 'Integrations::Jira', instance: true)
  end

  let(:project_tracker_data_to_backfill) do
    jira_tracker_data.create!(integration_id: project_integration.id)
  end

  let(:group_tracker_data_to_backfill) do
    jira_tracker_data.create!(integration_id: group_integration.id)
  end

  let(:organization_tracker_data_to_backfill) do
    jira_tracker_data.create!(integration_id: organization_integration.id)
  end

  let(:valid_group_tracker_data) do
    jira_tracker_data.create!(group_id: another_group.id, integration_id: another_group_integration.id)
  end

  before do
    ApplicationRecord.connection.execute('ALTER TABLE jira_tracker_data DROP CONSTRAINT IF EXISTS check_eca1fbd6bd;')
  end

  after do
    ApplicationRecord
      .connection
      .execute(
        'ALTER TABLE jira_tracker_data ADD CONSTRAINT check_eca1fbd6bd ' \
          'CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1));'
      )
  end

  describe "#up" do
    it 'sets sharding key for records that do not have it' do
      expect(project_tracker_data_to_backfill.project_id).to be_nil
      expect(project_tracker_data_to_backfill.group_id).to be_nil
      expect(project_tracker_data_to_backfill.organization_id).to be_nil

      expect(group_tracker_data_to_backfill.project_id).to be_nil
      expect(group_tracker_data_to_backfill.group_id).to be_nil
      expect(group_tracker_data_to_backfill.organization_id).to be_nil

      expect(organization_tracker_data_to_backfill.project_id).to be_nil
      expect(organization_tracker_data_to_backfill.group_id).to be_nil
      expect(organization_tracker_data_to_backfill.organization_id).to be_nil

      expect(valid_group_tracker_data.project_id).to be_nil
      expect(valid_group_tracker_data.group_id).to eq(another_group.id)
      expect(valid_group_tracker_data.organization_id).to be_nil

      migrate!

      expect(project_tracker_data_to_backfill.reload.project_id).to eq(project.id)
      expect(project_tracker_data_to_backfill.reload.group_id).to be_nil
      expect(project_tracker_data_to_backfill.reload.organization_id).to be_nil

      expect(group_tracker_data_to_backfill.reload.project_id).to be_nil
      expect(group_tracker_data_to_backfill.reload.group_id).to eq(group.id)
      expect(group_tracker_data_to_backfill.reload.organization_id).to be_nil

      expect(organization_tracker_data_to_backfill.reload.project_id).to be_nil
      expect(organization_tracker_data_to_backfill.reload.group_id).to be_nil
      expect(organization_tracker_data_to_backfill.reload.organization_id).to eq(organization.id)

      expect(valid_group_tracker_data.reload.project_id).to be_nil
      expect(valid_group_tracker_data.reload.group_id).to eq(another_group.id)
      expect(valid_group_tracker_data.reload.organization_id).to be_nil
    end
  end
end

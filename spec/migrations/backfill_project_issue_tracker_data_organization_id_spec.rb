# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillProjectIssueTrackerDataOrganizationId, feature_category: :integrations do
  let(:organizations) { table(:organizations) }
  let(:issue_tracker_data) { table(:issue_tracker_data) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:integrations) { table(:integrations) }

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

  let!(:integration) do
    integrations.create!(project_id: project.id, type_new: 'Integrations::Youtrack')
  end

  let(:tracker_data_to_backfill) do
    issue_tracker_data.create!(project_id: project.id, integration_id: integration.id, organization_id: organization.id)
  end

  let(:another_tracker_data_to_backfill) do
    issue_tracker_data.create!(project_id: project.id, integration_id: integration.id, organization_id: organization.id)
  end

  let(:valid_tracker_data) do
    issue_tracker_data.create!(project_id: project.id, integration_id: integration.id)
  end

  let(:group_tracker_data) do
    group_integration = integrations.create!(group_id: group.id, type_new: 'Integrations::Bugzilla')
    issue_tracker_data.create!(group_id: group.id, integration_id: group_integration.id)
  end

  let(:organization_tracker_data) do
    instance_integration = integrations.create!(
      instance: true,
      organization_id: organization.id,
      type_new: 'Integrations::Clickup'
    )

    issue_tracker_data.create!(organization_id: organization.id, integration_id: instance_integration.id)
  end

  before do
    ApplicationRecord.connection.execute('ALTER TABLE issue_tracker_data DROP CONSTRAINT IF EXISTS check_f02a3f53bf;')
  end

  after do
    ApplicationRecord
      .connection
      .execute(
        'ALTER TABLE issue_tracker_data ADD CONSTRAINT check_f02a3f53bf ' \
          'CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1));'
      )
  end

  describe "#up" do
    it 'sets organization_id to nil for project issue_tracker_data that have it' do
      expect(tracker_data_to_backfill.project_id).to eq(project.id)
      expect(tracker_data_to_backfill.organization_id).to eq(organization.id)

      expect(another_tracker_data_to_backfill.project_id).to eq(project.id)
      expect(another_tracker_data_to_backfill.organization_id).to eq(organization.id)

      expect(valid_tracker_data.project_id).to eq(project.id)
      expect(valid_tracker_data.organization_id).to be_nil

      expect(group_tracker_data.group_id).to eq(group.id)
      expect(group_tracker_data.organization_id).to be_nil

      expect(organization_tracker_data.organization_id).to eq(organization.id)
      expect(organization_tracker_data.project_id).to be_nil
      expect(organization_tracker_data.group_id).to be_nil

      migrate!

      expect(tracker_data_to_backfill.reload.project_id).to eq(project.id)
      expect(tracker_data_to_backfill.reload.organization_id).to be_nil

      expect(another_tracker_data_to_backfill.reload.project_id).to eq(project.id)
      expect(another_tracker_data_to_backfill.reload.organization_id).to be_nil

      expect(valid_tracker_data.reload.project_id).to eq(project.id)
      expect(valid_tracker_data.reload.organization_id).to be_nil

      expect(group_tracker_data.reload.group_id).to eq(group.id)
      expect(group_tracker_data.reload.organization_id).to be_nil

      expect(organization_tracker_data.reload.organization_id).to eq(organization.id)
      expect(organization_tracker_data.reload.project_id).to be_nil
      expect(organization_tracker_data.reload.group_id).to be_nil
    end
  end
end

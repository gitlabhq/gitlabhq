# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe BackfillGroupIntegrationsOrganizationId, feature_category: :integrations do
  let(:organizations) { table(:organizations) }
  let(:integrations) { table(:integrations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

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

  let(:integration_to_backfill) do
    integrations.create!(group_id: group.id, type_new: 'Integrations::Zentao', organization_id: organization.id)
  end

  let(:another_integration_to_backfill) do
    integrations.create!(group_id: group.id, type_new: 'Integrations::Telegram', organization_id: organization.id)
  end

  let(:valid_integration) do
    integrations.create!(group_id: group.id, type_new: 'Integrations::Discord')
  end

  let(:project_integration) do
    integrations.create!(project_id: project.id, type_new: 'Integrations::Discord')
  end

  let(:organization_integration) do
    integrations.create!(instance: true, organization_id: organization.id, type_new: 'Integrations::Zentao')
  end

  before do
    ApplicationRecord.connection.execute('ALTER TABLE integrations DROP CONSTRAINT IF EXISTS check_2aae034509;')
  end

  after do
    ApplicationRecord
      .connection
      .execute(
        'ALTER TABLE integrations ADD CONSTRAINT check_2aae034509 ' \
          'CHECK ((num_nonnulls(group_id, organization_id, project_id) = 1)) NOT VALID;'
      )
  end

  describe "#up" do
    it 'sets organization_id to nil for group integrations that have it' do
      expect(integration_to_backfill.group_id).to eq(group.id)
      expect(integration_to_backfill.organization_id).to eq(organization.id)

      expect(another_integration_to_backfill.group_id).to eq(group.id)
      expect(another_integration_to_backfill.organization_id).to eq(organization.id)

      expect(valid_integration.group_id).to eq(group.id)
      expect(valid_integration.organization_id).to be_nil

      expect(project_integration.project_id).to eq(project.id)
      expect(project_integration.organization_id).to be_nil

      expect(organization_integration.organization_id).to eq(organization.id)
      expect(organization_integration.project_id).to be_nil
      expect(organization_integration.group_id).to be_nil

      migrate!

      expect(integration_to_backfill.reload.group_id).to eq(group.id)
      expect(integration_to_backfill.reload.organization_id).to be_nil

      expect(another_integration_to_backfill.reload.group_id).to eq(group.id)
      expect(another_integration_to_backfill.reload.organization_id).to be_nil

      expect(valid_integration.reload.group_id).to eq(group.id)
      expect(valid_integration.reload.organization_id).to be_nil

      expect(project_integration.reload.project_id).to eq(project.id)
      expect(project_integration.reload.organization_id).to be_nil

      expect(organization_integration.reload.organization_id).to eq(organization.id)
      expect(organization_integration.reload.project_id).to be_nil
      expect(organization_integration.reload.group_id).to be_nil
    end
  end
end

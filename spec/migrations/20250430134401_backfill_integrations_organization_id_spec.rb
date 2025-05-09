# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillIntegrationsOrganizationId, feature_category: :integrations do
  let(:organizations) { table(:organizations) }
  let(:integrations) { table(:integrations) }
  let(:namespaces) { table(:namespaces) }

  let!(:default_organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:other_organization) { organizations.create!(id: 2, name: 'Other', path: 'other') }
  let!(:group) { namespaces.create!(name: 'bar', path: 'bar', type: 'Group', organization_id: 1) }

  let!(:integration_without_organization) do
    integrations.create!(
      instance: true,
      organization_id: nil,
      type_new: 'Integrations::MockMonitoring'
    )
  end

  let!(:integration_with_organization) do
    integrations.create!(
      instance: true,
      organization_id: other_organization.id,
      type_new: 'Integrations::MockCi'
    )
  end

  let!(:non_instance_integration) do
    integrations.create!(
      instance: false,
      organization_id: nil,
      type_new: 'Integrations::Asana',
      group_id: group.id
    )
  end

  before do
    migrate!
  end

  describe "#up" do
    it 'updates instance integrations with null organization id to 1' do
      expect(integration_without_organization.reload.organization_id).to eq(1)
    end

    it 'does not update integrations with an existing organization id' do
      expect(integration_with_organization.reload.organization_id).to eq(other_organization.id)
    end

    it 'does not update non-instance integration' do
      expect(non_instance_integration.reload.organization_id).to be_nil
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupUntetheredIntegrations, feature_category: :integrations do
  let(:organizations) { table(:organizations) }
  let(:integrations) { table(:integrations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let!(:default_organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:other_organization) { organizations.create!(id: 2, name: 'Other', path: 'other') }
  let!(:group) { namespaces.create!(name: 'bar', path: 'bar', type: 'Group', organization_id: 1) }

  let!(:project) do
    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: group.id,
      organization_id: 1,
      project_namespace_id: group.id
    )
  end

  let!(:untethered_integration) do
    integrations.create!(
      instance: false,
      group_id: nil,
      project_id: nil,
      type_new: 'Integrations::MockMonitoring'
    )
  end

  let!(:another_untethered_integration) do
    integrations.create!(
      instance: false,
      group_id: nil,
      project_id: nil,
      type_new: 'Integrations::MockCi'
    )
  end

  let!(:tethered_integration) do
    integrations.create!(
      instance: false,
      group_id: group.id,
      type_new: 'Integrations::MockCi'
    )
  end

  let!(:another_tethered_integration) do
    integrations.create!(
      instance: false,
      project_id: project.id,
      group_id: nil,
      type_new: 'Integrations::Asana'
    )
  end

  describe "#up" do
    it 'removes untethered integrations' do
      expect(integrations.count).to eq(4)
      expect(untethered_integration).to be_present
      expect(another_untethered_integration).to be_present

      migrate!

      expect(integrations.count).to eq(2)
      expect(tethered_integration.reload).to be_present
      expect(another_tethered_integration.reload).to be_present
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProjectsOrganizationId, feature_category: :groups_and_projects do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }

  let!(:default_organization) { organizations.create!(id: 1, name: 'Default', path: 'default') }
  let!(:other_organization) { organizations.create!(name: 'Other', path: 'other') }

  let!(:project_without_organization) do
    namespace = namespaces.create!(name: 'foo', path: 'foo')
    projects.create!(namespace_id: namespace.id, project_namespace_id: namespace.id, organization_id: nil)
  end

  let!(:project_with_organization) do
    namespace = namespaces.create!(name: 'bar', path: 'bar')
    projects.create!(
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: other_organization.id
    )
  end

  before do
    migrate!
  end

  describe "#up" do
    it 'updates projects with null organization id to 1' do
      expect(project_without_organization.reload.organization_id).to eq(1)
    end

    it 'does not update projects with an existing organization id' do
      expect(project_with_organization.reload.organization_id).to eq(other_organization.id)
    end
  end
end

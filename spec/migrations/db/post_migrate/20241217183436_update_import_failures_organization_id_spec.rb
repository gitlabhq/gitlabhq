# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe UpdateImportFailuresOrganizationId, migration: :gitlab_main, feature_category: :cell do
  let(:import_failures) { table(:import_failures) }
  let(:projects) { table(:projects) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }

  let!(:default_organization) { organizations.create!(id: 1, path: '/') }
  let!(:other_organization) { organizations.create!(id: 2, path: '/other') }

  let(:group) do
    namespaces.create!(name: 'group1', path: 'group1', type: 'Group', organization_id: default_organization.id)
  end

  let!(:project_namespace) do
    namespaces.create!(name: 'project1', path: 'project1', type: 'Project', organization_id: default_organization.id)
  end

  let(:project) do
    projects.create!(
      name: 'foo', path: 'foo', namespace_id: group.id, project_namespace_id: project_namespace.id,
      organization_id: default_organization.id
    )
  end

  let!(:import_failure_with_organization) { import_failures.create!(organization_id: other_organization.id) }
  let!(:import_failure_with_group) { import_failures.create!(group_id: group.id) }
  let!(:import_failure_with_project) { import_failures.create!(project_id: project.id) }
  let!(:import_failure_without_any) { import_failures.create! }

  describe '#up' do
    it 'updates organization_id when no other sharding key exists' do
      migrate!

      expect(import_failure_with_organization.reload.organization_id).to eq(2)
      expect(import_failure_with_group.reload.organization_id).to be_nil
      expect(import_failure_with_project.reload.organization_id).to be_nil
      expect(import_failure_without_any.reload.organization_id).to eq(1)
    end
  end
end

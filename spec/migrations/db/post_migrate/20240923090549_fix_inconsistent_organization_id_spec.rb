# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixInconsistentOrganizationId, migration: :gitlab_main, feature_category: :cell do
  let(:organization_2) { table(:organizations).create!(path: 'organization_2') }
  let(:organization_3) { table(:organizations).create!(path: 'organization_3') }
  let(:organization_4) { table(:organizations).create!(path: 'organization_4') }
  let(:organization_5) { table(:organizations).create!(path: 'organization_5') }
  let(:organization_6) { table(:organizations).create!(path: 'organization_6') }
  let(:organization_7) { table(:organizations).create!(path: 'organization_7') }
  let(:organization_8) { table(:organizations).create!(path: 'organization_8') }
  let(:organization_9) { table(:organizations).create!(path: 'organization_9') }

  # Inconsistent data:
  let!(:parent_namespace_1) do
    table(:namespaces).create!(type: 'Group', name: 'parent', path: 'parent', organization_id: organization_2.id)
  end

  let!(:namespace_1) do
    table(:namespaces).create!(type: 'Group', name: 'child', path: 'child', parent_id: parent_namespace_1.id,
      organization_id: organization_3.id)
  end

  let!(:namespace_2) do
    table(:namespaces).create!(type: 'Group', name: 'parent group of project', path: 'parent-group-of-project',
      organization_id: organization_4.id)
  end

  let!(:project_namespace_1) do
    table(:namespaces).create!(type: 'Project', name: 'project namespace', path: 'project_namespace',
      organization_id: organization_5.id)
  end

  let!(:project_1) do
    table(:projects).create!(namespace_id: namespace_2.id,
      project_namespace_id: project_namespace_1.id, organization_id: organization_5.id)
  end

  let!(:namespace_2_1) do
    table(:namespaces).create!(parent_id: namespace_2.id, type: 'Group', name: 'sub-group of project',
      path: 'sub-group-of-project', organization_id: organization_6.id)
  end

  let!(:project_namespace_2_1) do
    table(:namespaces).create!(type: 'Project', name: 'project namespace 2 1', path: 'project_namespace-2-1',
      organization_id: organization_7.id)
  end

  let!(:project_2_1) do
    table(:projects).create!(namespace_id: namespace_2_1.id,
      project_namespace_id: project_namespace_2_1.id, organization_id: organization_7.id)
  end

  # Valid data
  let!(:parent_namespace_2) do
    table(:namespaces).create!(type: 'Group', name: 'parent 2', path: 'parent2', organization_id: organization_8.id)
  end

  let!(:namespace_3) do
    table(:namespaces).create!(type: 'Group', name: 'child 2', path: 'child2', parent_id: parent_namespace_2.id,
      organization_id: organization_8.id)
  end

  let!(:namespace_4) do
    table(:namespaces).create!(type: 'Group', name: 'parent of project 2', path: 'parent-of-project-2 ',
      organization_id: organization_9.id)
  end

  let!(:project_namespace_2) do
    table(:namespaces).create!(type: 'Project', name: 'project namespace 2', path: 'project_namespace_2',
      organization_id: organization_9.id)
  end

  let!(:project_2) do
    table(:projects).create!(namespace_id: namespace_4.id,
      project_namespace_id: project_namespace_2.id, organization_id: organization_9.id)
  end

  describe '#up' do
    it 'sets organization_id to parent organization if organization_ids do not match' do
      migrate!

      expect(namespace_1.reload.organization_id).to eq(organization_2.id)
      expect(project_1.reload.organization_id).to eq(organization_4.id)
      expect(project_2_1.reload.organization_id).to eq(organization_4.id)

      expect(namespace_3.reload.organization_id).to eq(organization_8.id)
      expect(project_2.reload.organization_id).to eq(organization_9.id)
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe FixInconsistentOrganizationId, migration: :gitlab_main, feature_category: :cell do
  # Inconsistent data:
  let!(:parent_namespace_1) do
    table(:namespaces).create!(type: 'Group', name: 'parent', path: 'parent', organization_id: 2)
  end

  let!(:namespace_1) do
    table(:namespaces).create!(type: 'Group', name: 'child', path: 'child', parent_id: parent_namespace_1.id,
      organization_id: 3)
  end

  let!(:namespace_2) do
    table(:namespaces).create!(type: 'Group', name: 'parent group of project', path: 'parent-group-of-project',
      organization_id: 4)
  end

  let!(:project_namespace_1) do
    table(:namespaces).create!(type: 'Project', name: 'project namespace', path: 'project_namespace',
      organization_id: 5)
  end

  let!(:project_1) do
    table(:projects).create!(namespace_id: namespace_2.id,
      project_namespace_id: project_namespace_1.id, organization_id: 5)
  end

  let!(:namespace_2_1) do
    table(:namespaces).create!(parent_id: namespace_2.id, type: 'Group', name: 'sub-group of project',
      path: 'sub-group-of-project', organization_id: 6)
  end

  let!(:project_namespace_2_1) do
    table(:namespaces).create!(type: 'Project', name: 'project namespace 2 1', path: 'project_namespace-2-1',
      organization_id: 7)
  end

  let!(:project_2_1) do
    table(:projects).create!(namespace_id: namespace_2_1.id,
      project_namespace_id: project_namespace_2_1.id, organization_id: 7)
  end

  # Valid data
  let!(:parent_namespace_2) do
    table(:namespaces).create!(type: 'Group', name: 'parent 2', path: 'parent2', organization_id: 8)
  end

  let!(:namespace_3) do
    table(:namespaces).create!(type: 'Group', name: 'child 2', path: 'child2', parent_id: parent_namespace_2.id,
      organization_id: 8)
  end

  let!(:namespace_4) do
    table(:namespaces).create!(type: 'Group', name: 'parent of project 2', path: 'parent-of-project-2 ',
      organization_id: 9)
  end

  let!(:project_namespace_2) do
    table(:namespaces).create!(type: 'Project', name: 'project namespace 2', path: 'project_namespace_2',
      organization_id: 9)
  end

  let!(:project_2) do
    table(:projects).create!(namespace_id: namespace_4.id,
      project_namespace_id: project_namespace_2.id, organization_id: 9)
  end

  describe '#up' do
    it 'sets organization_id to parent organization if organization_ids do not match' do
      migrate!

      expect(namespace_1.reload.organization_id).to eq(2)
      expect(project_1.reload.organization_id).to eq(4)
      expect(project_2_1.reload.organization_id).to eq(4)

      expect(namespace_3.reload.organization_id).to eq(8)
      expect(project_2.reload.organization_id).to eq(9)
    end
  end
end

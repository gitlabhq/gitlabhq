# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillPsmMaintenanceTasksProjectIdAndRootNamespaceId,
  feature_category: :secrets_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_secrets_managers) { table(:project_secrets_managers) }
  let(:maintenance_tasks) { table(:project_secrets_manager_maintenance_tasks) }
  let(:users) { table(:users) }

  let!(:organization) { organizations.create!(name: 'test', path: 'test') }

  let!(:root_group) do
    namespaces.create!(name: 'root', path: 'root', type: 'Group', organization_id: organization.id, traversal_ids: [])
      .tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  let!(:subgroup) do
    namespaces.create!(
      name: 'sub', path: 'sub', type: 'Group',
      parent_id: root_group.id, organization_id: organization.id, traversal_ids: []
    ).tap { |ns| ns.update!(traversal_ids: [root_group.id, ns.id]) }
  end

  let!(:project_namespace) do
    namespaces.create!(
      name: 'proj_ns', path: 'proj_ns', type: 'Project',
      organization_id: organization.id, traversal_ids: []
    ).tap { |ns| ns.update!(traversal_ids: [root_group.id, subgroup.id, ns.id]) }
  end

  let!(:project) do
    projects.create!(
      name: 'test_project', path: 'test_project',
      namespace_id: subgroup.id, project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  let!(:user) do
    users.create!(username: 'test_user', email: 'test@example.com', projects_limit: 10,
      organization_id: organization.id)
  end

  let!(:secrets_manager) do
    project_secrets_managers.create!(project_id: project.id, namespace_path: "group_#{root_group.id}",
      project_path: "project_#{project.id}")
  end

  describe '#up' do
    it 'backfills project_id, root_namespace_id, and parent_group_id correctly' do
      task = maintenance_tasks.create!(
        project_secrets_manager_id: secrets_manager.id,
        user_id: user.id,
        action: 1,
        organization_id: organization.id
      )

      expect { migrate! }
        .to change { task.reload.project_id }.from(nil).to(project.id)
        .and change { task.reload.root_namespace_id }.from(nil).to(root_group.id)
        .and change { task.reload.parent_group_id }.from(nil).to(subgroup.id)
    end

    it 'is idempotent when values are already populated' do
      task = maintenance_tasks.create!(
        project_secrets_manager_id: secrets_manager.id,
        user_id: user.id,
        action: 1,
        organization_id: organization.id,
        project_id: project.id,
        root_namespace_id: root_group.id,
        parent_group_id: subgroup.id
      )

      expect { migrate! }
        .to not_change { task.reload.project_id }
        .and not_change { task.reload.root_namespace_id }
        .and not_change { task.reload.parent_group_id }
    end
  end
end

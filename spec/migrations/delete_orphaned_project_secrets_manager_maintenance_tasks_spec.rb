# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteOrphanedProjectSecretsManagerMaintenanceTasks, feature_category: :secrets_management do
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_secrets_managers) { table(:project_secrets_managers) }
  let(:maintenance_tasks) { table(:project_secrets_manager_maintenance_tasks) }

  let(:organization) { organizations.create!(name: 'Default', path: 'default') }
  let(:user1) do
    users.create!(
      email: 'user1@example.com',
      username: 'user1',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:user2) do
    users.create!(
      email: 'user2@example.com',
      username: 'user2',
      projects_limit: 10,
      organization_id: organization.id
    )
  end

  let(:namespace) do
    namespaces.create!(
      name: 'namespace',
      path: 'namespace',
      organization_id: organization.id
    )
  end

  let(:project) do
    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization.id
    )
  end

  let!(:valid_task) do
    ns = namespaces.create!(name: 'namespace1', path: 'namespace1', organization_id: organization.id)
    proj = projects.create!(
      name: 'project1',
      path: 'project1',
      namespace_id: ns.id,
      project_namespace_id: ns.id,
      organization_id: organization.id
    )
    psm = project_secrets_managers.create!(
      project_id: proj.id,
      status: 0
    )
    maintenance_tasks.create!(
      user_id: user1.id,
      project_secrets_manager_id: psm.id,
      action: 0
    )
  end

  let!(:orphaned_task) do
    ns = namespaces.create!(name: 'namespace2', path: 'namespace2', organization_id: organization.id)
    proj = projects.create!(
      name: 'project2',
      path: 'project2',
      namespace_id: ns.id,
      project_namespace_id: ns.id,
      organization_id: organization.id
    )
    psm = project_secrets_managers.create!(
      project_id: proj.id,
      status: 0
    )
    # Create task then delete the user to make it orphaned
    task = maintenance_tasks.create!(
      user_id: user2.id,
      project_secrets_manager_id: psm.id,
      action: 0
    )

    # Delete user to create orphan
    users.where(id: user2.id).delete_all

    task
  end

  let!(:orphaned_task_non_existent_user) do
    ns = namespaces.create!(name: 'namespace3', path: 'namespace3', organization_id: organization.id)
    proj = projects.create!(
      name: 'project3',
      path: 'project3',
      namespace_id: ns.id,
      project_namespace_id: ns.id,
      organization_id: organization.id
    )
    psm = project_secrets_managers.create!(
      project_id: proj.id,
      status: 0
    )
    # Create task with non-existent user_id directly
    non_existent_user_id = users.maximum(:id).to_i + 1000

    maintenance_tasks.create!(
      user_id: non_existent_user_id,
      project_secrets_manager_id: psm.id,
      action: 0
    )
  end

  describe '#up' do
    it 'deletes tasks with non-existent user_id' do
      expect { migrate! }
        .to change { maintenance_tasks.count }.from(3).to(1)
    end

    it 'keeps tasks with valid user_id', :aggregate_failures do
      migrate!

      expect(maintenance_tasks.exists?(valid_task.id)).to be(true)
      expect(maintenance_tasks.exists?(orphaned_task.id)).to be(false)
      expect(maintenance_tasks.exists?(orphaned_task_non_existent_user.id)).to be(false)
    end

    it 'is idempotent' do
      migrate!

      expect { schema_migrate_down! && migrate! }
        .not_to change { maintenance_tasks.count }
    end
  end

  describe '#down' do
    it 'is a no-op (cannot restore deleted data)' do
      migrate!

      expect { schema_migrate_down! }
        .not_to change { maintenance_tasks.count }
    end
  end
end

# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillProjectSecretsManagerMaintenanceTasksOrganizationId, feature_category: :secrets_management do
  let(:users) { table(:users) }
  let(:task_without_org_1) do
    ns = namespaces.create!(name: 'namespace1', path: 'namespace1', organization_id: organization1.id)
    proj = projects.create!(
      name: 'project1',
      path: 'project1',
      namespace_id: ns.id,
      project_namespace_id: ns.id,
      organization_id: organization1.id
    )
    psm = project_secrets_managers.create!(project_id: proj.id, status: 0)
    maintenance_tasks.create!(
      user_id: user1.id,
      project_secrets_manager_id: psm.id,
      action: 0,
      organization_id: nil
    )
  end

  let(:task_without_org_2) do
    ns = namespaces.create!(name: 'namespace2', path: 'namespace2', organization_id: organization1.id)
    proj = projects.create!(
      name: 'project2',
      path: 'project2',
      namespace_id: ns.id,
      project_namespace_id: ns.id,
      organization_id: organization1.id
    )
    psm = project_secrets_managers.create!(project_id: proj.id, status: 0)
    maintenance_tasks.create!(
      user_id: user2.id,
      project_secrets_manager_id: psm.id,
      action: 0,
      organization_id: nil
    )
  end

  let(:task_with_org) do
    ns = namespaces.create!(name: 'namespace3', path: 'namespace3', organization_id: organization1.id)
    proj = projects.create!(
      name: 'project3',
      path: 'project3',
      namespace_id: ns.id,
      project_namespace_id: ns.id,
      organization_id: organization1.id
    )
    psm = project_secrets_managers.create!(project_id: proj.id, status: 0)
    maintenance_tasks.create!(
      user_id: user1.id,
      project_secrets_manager_id: psm.id,
      action: 0,
      organization_id: organization2.id
    )
  end

  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_secrets_managers) { table(:project_secrets_managers) }
  let(:maintenance_tasks) { table(:project_secrets_manager_maintenance_tasks) }
  let(:organization1) { organizations.create!(name: 'Org 1', path: 'org-1') }
  let(:organization2) { organizations.create!(name: 'Org 2', path: 'org-2') }
  let(:user1) do
    users.create!(
      email: 'user1@example.com',
      username: 'user1',
      projects_limit: 10,
      organization_id: organization1.id
    )
  end

  let(:user2) do
    users.create!(
      email: 'user2@example.com',
      username: 'user2',
      projects_limit: 10,
      organization_id: organization2.id
    )
  end

  let(:namespace) do
    namespaces.create!(
      name: 'namespace',
      path: 'namespace',
      organization_id: organization1.id
    )
  end

  let(:project) do
    projects.create!(
      name: 'project',
      path: 'project',
      namespace_id: namespace.id,
      project_namespace_id: namespace.id,
      organization_id: organization1.id
    )
  end

  before do
    # Drop trigger and constraint to ensure test data is created with nil organization_id
    ActiveRecord::Base.connection.execute(<<~SQL)
      DROP TRIGGER IF EXISTS trigger_project_secrets_manager_maintenance_tasks_organization_id
      ON project_secrets_manager_maintenance_tasks;
      ALTER TABLE project_secrets_manager_maintenance_tasks
      DROP CONSTRAINT IF EXISTS check_organization_id_not_null;
    SQL

    # Create test data after dropping constraints
    task_without_org_1
    task_without_org_2

    # Recreate trigger
    ActiveRecord::Base.connection.execute(<<~SQL)
      CREATE TRIGGER trigger_project_secrets_manager_maintenance_tasks_organization_id
      BEFORE INSERT OR UPDATE ON project_secrets_manager_maintenance_tasks
      FOR EACH ROW EXECUTE FUNCTION project_secrets_manager_maintenance_tasks_organization_id();
    SQL

    task_with_org
  end

  describe '#up' do
    it 'backfills organization_id from users table' do
      expect { migrate! }
        .to change { maintenance_tasks.where(organization_id: nil).count }.from(2).to(0)
    end

    it 'sets correct organization_id based on user relationship', :aggregate_failures do
      migrate!

      expect(task_without_org_1.reload.organization_id).to eq(organization1.id)
      expect(task_without_org_2.reload.organization_id).to eq(organization2.id)
    end

    it 'does not override existing organization_id values' do
      migrate!

      expect(task_with_org.reload.organization_id).to eq(organization2.id)
    end

    it 'is idempotent' do
      migrate!

      expect { schema_migrate_down! && migrate! }
        .not_to change { task_without_org_1.reload.organization_id }
    end
  end

  describe '#down' do
    it 'is a no-op (cannot rollback data changes)' do
      migrate!

      expect { schema_migrate_down! }
        .not_to change { task_without_org_1.reload.organization_id }
    end
  end
end

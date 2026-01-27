# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe AddTriggerForProjectSecretsManagerMaintenanceTasksOrganizationId, feature_category: :secrets_management do
  let(:users) { table(:users) }
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:project_secrets_managers) { table(:project_secrets_managers) }
  let(:maintenance_tasks) { table(:project_secrets_manager_maintenance_tasks) }

  let(:organization) { organizations.create!(name: 'Default', path: 'default') }
  let(:user) do
    users.create!(
      email: 'user@example.com',
      username: 'user',
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

  let(:project_secrets_manager) do
    project_secrets_managers.create!(
      project_id: project.id,
      status: 0
    )
  end

  describe '#up' do
    before do
      migrate!
    end

    context 'when inserting new records' do
      it 'automatically sets organization_id from users table' do
        task = maintenance_tasks.create!(
          user_id: user.id,
          project_secrets_manager_id: project_secrets_manager.id,
          action: 0,
          organization_id: nil
        )

        expect(task.reload.organization_id).to eq(organization.id)
      end

      it 'does not override existing organization_id' do
        other_organization = organizations.create!(name: 'Other', path: 'other')

        task = maintenance_tasks.create!(
          user_id: user.id,
          project_secrets_manager_id: project_secrets_manager.id,
          action: 0,
          organization_id: other_organization.id
        )

        expect(task.reload.organization_id).to eq(other_organization.id)
      end
    end

    context 'when updating existing records' do
      it 'sets organization_id when updating a record with nil organization_id' do
        # Drop trigger temporarily to create record without organization_id
        ActiveRecord::Base.connection.execute(<<~SQL)
          DROP TRIGGER IF EXISTS trigger_project_secrets_manager_maintenance_tasks_organization_id
          ON project_secrets_manager_maintenance_tasks;
        SQL

        task = maintenance_tasks.create!(
          user_id: user.id,
          project_secrets_manager_id: project_secrets_manager.id,
          action: 0,
          organization_id: nil
        )

        expect(task.reload.organization_id).to be_nil

        # Recreate trigger
        ActiveRecord::Base.connection.execute(<<~SQL)
          CREATE TRIGGER trigger_project_secrets_manager_maintenance_tasks_organization_id
          BEFORE INSERT OR UPDATE ON project_secrets_manager_maintenance_tasks
          FOR EACH ROW EXECUTE FUNCTION project_secrets_manager_maintenance_tasks_organization_id();
        SQL

        # Update to trigger the function
        task.update!(retry_count: 1)

        expect(task.reload.organization_id).to eq(organization.id)
      end
    end
  end

  describe '#down' do
    it 'removes the trigger and function' do
      migrate!
      schema_migrate_down!

      expect do
        maintenance_tasks.create!(
          user_id: user.id,
          project_secrets_manager_id: project_secrets_manager.id,
          action: 0,
          organization_id: nil
        )
      end.not_to raise_error

      task = maintenance_tasks.last
      expect(task.organization_id).to be_nil
    end
  end
end

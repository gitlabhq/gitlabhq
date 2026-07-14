# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupLegacyProjectSecretsManagers, feature_category: :secrets_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:secrets_managers) { table(:project_secrets_managers) }
  let(:maintenance_tasks) { table(:project_secrets_manager_maintenance_tasks) }

  let(:organization) { organizations.create!(name: 'test', path: 'test') }
  let(:root_group) do
    namespaces.create!(name: 'root', path: 'root', type: 'Group', organization_id: organization.id, traversal_ids: [])
      .tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  def create_project(path)
    project_namespace = namespaces.create!(
      name: path, path: path, type: 'Project',
      parent_id: root_group.id, organization_id: organization.id, traversal_ids: [root_group.id]
    )
    projects.create!(
      name: path, path: path,
      namespace_id: root_group.id, project_namespace_id: project_namespace.id,
      organization_id: organization.id
    )
  end

  def create_sm(project_id:, project_path:, status:, created_at: 2.hours.ago)
    secrets_managers.create!(
      project_id: project_id,
      project_path: project_path,
      status: status,
      organization_id: organization.id,
      root_namespace_id: root_group.id,
      created_at: created_at,
      updated_at: created_at
    )
  end

  describe '#up' do
    let(:provisioning) { 0 }
    let(:active) { 1 }
    let(:deprovisioning) { 2 }
    let(:deprovision_action) { 1 }

    context 'with orphan SMs (project_id IS NULL)' do
      let!(:orphan_null_path) { create_sm(project_id: nil, project_path: nil, status: active) }
      let!(:orphan_with_path) { create_sm(project_id: nil, project_path: 'project_999', status: provisioning) }

      it 'deletes orphans regardless of cached path' do
        migrate!

        expect(secrets_managers.where(id: orphan_null_path.id)).to be_empty
        expect(secrets_managers.where(id: orphan_with_path.id)).to be_empty
      end

      it 'does not create maintenance tasks for orphans (trigger orphan guard skips)' do
        expect { migrate! }.not_to change { maintenance_tasks.count }
      end
    end

    context 'with stuck non-orphan SMs past the threshold' do
      let!(:project_old_provisioning) { create_project('stuck-old-prov') }
      let!(:project_old_deprovisioning) { create_project('stuck-old-deprov') }

      let!(:stuck_old_provisioning) do
        create_sm(project_id: project_old_provisioning.id, project_path: "project_#{project_old_provisioning.id}",
          status: provisioning, created_at: 2.hours.ago)
      end

      let!(:stuck_old_deprovisioning) do
        create_sm(project_id: project_old_deprovisioning.id, project_path: "project_#{project_old_deprovisioning.id}",
          status: deprovisioning, created_at: 2.hours.ago)
      end

      it 'deletes them' do
        migrate!

        expect(secrets_managers.where(id: stuck_old_provisioning.id)).to be_empty
        expect(secrets_managers.where(id: stuck_old_deprovisioning.id)).to be_empty
      end

      it 'fires the trigger so each gets a deprovision task carrying the snapshot ids' do
        migrate!

        task = maintenance_tasks.find_by(project_id: project_old_provisioning.id)
        expect(task.action).to eq(deprovision_action)
        expect(task.organization_id).to eq(organization.id)
        expect(task.root_namespace_id).to eq(root_group.id)
      end
    end

    context 'with fresh non-orphan SMs inside the stuck threshold' do
      let!(:project_fresh) { create_project('fresh') }
      let!(:fresh_provisioning) do
        create_sm(project_id: project_fresh.id, project_path: "project_#{project_fresh.id}",
          status: provisioning, created_at: 30.seconds.ago)
      end

      it 'leaves them alone' do
        expect { migrate! }.not_to change { secrets_managers.where(id: fresh_provisioning.id).count }
      end

      it 'does not create a task for them' do
        expect { migrate! }.not_to change { maintenance_tasks.count }
      end
    end

    context 'with healthy active SMs' do
      let!(:project_healthy) { create_project('healthy') }
      let!(:healthy_active) do
        create_sm(project_id: project_healthy.id, project_path: "project_#{project_healthy.id}",
          status: active, created_at: 2.hours.ago)
      end

      it 'leaves them alone regardless of age' do
        expect { migrate! }.not_to change { secrets_managers.where(id: healthy_active.id).count }
      end
    end
  end
end

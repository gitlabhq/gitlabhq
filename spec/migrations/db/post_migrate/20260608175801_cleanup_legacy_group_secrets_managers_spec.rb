# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe CleanupLegacyGroupSecretsManagers, feature_category: :secrets_management do
  let(:organizations) { table(:organizations) }
  let(:namespaces) { table(:namespaces) }
  let(:secrets_managers) { table(:group_secrets_managers) }
  let(:maintenance_tasks) { table(:group_secrets_manager_maintenance_tasks) }

  let(:organization) { organizations.create!(name: 'test', path: 'test') }

  def create_group(path)
    namespaces.create!(name: path, path: path, type: 'Group', organization_id: organization.id, traversal_ids: [])
      .tap { |ns| ns.update!(traversal_ids: [ns.id]) }
  end

  def create_sm(group_id:, group_path:, status:, created_at: 2.hours.ago, root_namespace_id: nil)
    secrets_managers.create!(
      group_id: group_id,
      group_path: group_path,
      status: status,
      organization_id: organization.id,
      root_namespace_id: root_namespace_id || group_id || create_group('root').id,
      created_at: created_at,
      updated_at: created_at
    )
  end

  describe '#up' do
    let(:provisioning) { 0 }
    let(:active) { 1 }
    let(:deprovisioning) { 2 }
    let(:deprovision_action) { 1 }

    context 'with orphan SMs (group_id IS NULL)' do
      let!(:root) { create_group('root') }
      let!(:orphan_null_path) do
        create_sm(group_id: nil, group_path: nil, status: active, root_namespace_id: root.id)
      end

      let!(:orphan_with_path) do
        create_sm(group_id: nil, group_path: 'group_999', status: provisioning, root_namespace_id: root.id)
      end

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
      let!(:group_old_provisioning) { create_group('stuck-old-prov') }
      let!(:group_old_deprovisioning) { create_group('stuck-old-deprov') }

      let!(:stuck_old_provisioning) do
        create_sm(group_id: group_old_provisioning.id, group_path: "group_#{group_old_provisioning.id}",
          status: provisioning, created_at: 2.hours.ago)
      end

      let!(:stuck_old_deprovisioning) do
        create_sm(group_id: group_old_deprovisioning.id, group_path: "group_#{group_old_deprovisioning.id}",
          status: deprovisioning, created_at: 2.hours.ago)
      end

      it 'deletes them' do
        migrate!

        expect(secrets_managers.where(id: stuck_old_provisioning.id)).to be_empty
        expect(secrets_managers.where(id: stuck_old_deprovisioning.id)).to be_empty
      end

      it 'fires the trigger so each gets a deprovision task carrying the snapshot ids' do
        migrate!

        task = maintenance_tasks.find_by(group_id: group_old_provisioning.id)
        expect(task.action).to eq(deprovision_action)
        expect(task.organization_id).to eq(organization.id)
        expect(task.root_namespace_id).to eq(group_old_provisioning.id)
      end
    end

    context 'with fresh non-orphan SMs inside the stuck threshold' do
      let!(:group_fresh) { create_group('fresh') }
      let!(:fresh_provisioning) do
        create_sm(group_id: group_fresh.id, group_path: "group_#{group_fresh.id}",
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
      let!(:group_healthy) { create_group('healthy') }
      let!(:healthy_active) do
        create_sm(group_id: group_healthy.id, group_path: "group_#{group_healthy.id}",
          status: active, created_at: 2.hours.ago)
      end

      it 'leaves them alone regardless of age' do
        expect { migrate! }.not_to change { secrets_managers.where(id: healthy_active.id).count }
      end
    end
  end
end

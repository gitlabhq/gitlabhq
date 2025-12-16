# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOrganizationIdKeys, feature_category: :system_access do
  let!(:default_organization) { table(:organizations).create!(id: 1, path: 'default') }
  let!(:organization1) { table(:organizations).create!(name: 'Organization 1', path: 'org1') }
  let!(:organization2) { table(:organizations).create!(name: 'Organization 2', path: 'org2') }

  let!(:namespace1) do
    table(:namespaces).create!(name: 'namespace1', path: 'namespace1', organization_id: organization1.id)
  end

  let!(:namespace2) do
    table(:namespaces).create!(name: 'namespace2', path: 'namespace2', organization_id: organization2.id)
  end

  let!(:user_with_org1) do
    table(:users).create!(
      email: 'user1@example.com',
      username: 'user1',
      projects_limit: 10,
      organization_id: organization1.id
    )
  end

  let!(:user_with_org2) do
    table(:users).create!(
      email: 'user2@example.com',
      username: 'user2',
      projects_limit: 10,
      organization_id: organization2.id
    )
  end

  let!(:project1) do
    table(:projects).create!(
      name: 'project1',
      path: 'project1',
      namespace_id: namespace1.id,
      organization_id: organization1.id,
      project_namespace_id: namespace1.id
    )
  end

  let!(:project2) do
    table(:projects).create!(
      name: 'project2',
      path: 'project2',
      namespace_id: namespace2.id,
      organization_id: organization2.id,
      project_namespace_id: namespace2.id
    )
  end

  let!(:ssh_key_with_org1) do
    table(:keys).create!(
      title: 'SSH Key 1',
      key: generate_ssh_key,
      user_id: user_with_org1.id,
      type: nil,
      organization_id: nil
    )
  end

  let!(:ssh_key_with_org2) do
    table(:keys).create!(
      title: 'SSH Key 2',
      key: generate_ssh_key,
      user_id: user_with_org2.id,
      type: 'Key',
      organization_id: nil
    )
  end

  let(:ssh_key_already_backfilled) do
    table(:keys).create!(
      title: 'SSH Key 4',
      key: generate_ssh_key,
      user_id: user_with_org1.id,
      type: nil,
      organization_id: organization1.id
    )
  end

  # Deploy Keys (STI model - stored directly in keys table with type: 'DeployKey')
  let!(:deploy_key1) do
    table(:keys).create!(
      title: 'Deploy Key 1',
      key: generate_ssh_key,
      type: 'DeployKey',
      user_id: nil,
      organization_id: nil
    )
  end

  let(:deploy_key2) do
    table(:keys).create!(
      title: 'Deploy Key 2',
      key: generate_ssh_key,
      type: 'DeployKey',
      user_id: nil,
      organization_id: nil
    )
  end

  let(:deploy_key_orphaned) do
    table(:keys).create!(
      title: 'Deploy Key Orphaned',
      key: generate_ssh_key,
      type: 'DeployKey',
      user_id: nil,
      organization_id: nil
    )
  end

  let(:deploy_key_already_backfilled) do
    table(:keys).create!(
      title: 'Deploy Key Already Backfilled',
      key: generate_ssh_key,
      type: 'DeployKey',
      user_id: nil,
      organization_id: organization1.id
    )
  end

  # Deploy key project associations
  let!(:deploy_key_project1) do
    table(:deploy_keys_projects).create!(deploy_key_id: deploy_key1.id, project_id: project1.id)
  end

  let(:deploy_key_project2) do
    table(:deploy_keys_projects).create!(deploy_key_id: deploy_key2.id, project_id: project2.id)
  end

  describe '#perform' do
    def perform_migration
      described_class.new(
        start_id: table(:keys).minimum(:id),
        end_id: table(:keys).maximum(:id),
        batch_table: :keys,
        batch_column: :id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: ActiveRecord::Base.connection
      ).perform
    end

    it 'backfills organization_id for SSH keys with valid users' do
      expect { perform_migration }
        .to change { ssh_key_with_org1.reload.organization_id }.from(nil).to(organization1.id)
        .and change { ssh_key_with_org2.reload.organization_id }.from(nil).to(organization2.id)
    end

    it 'backfills organization_id for deploy keys with valid projects' do
      deploy_key2
      deploy_key_project2

      expect { perform_migration }
        .to change { deploy_key1.reload.organization_id }.from(nil).to(organization1.id)
        .and change { deploy_key2.reload.organization_id }.from(nil).to(organization2.id)
    end

    it 'update organization_id for orphaned deploy_keys' do
      deploy_key_orphaned

      expect { perform_migration }
        .to change { deploy_key_orphaned.reload.organization_id }
        .from(nil).to(1)
    end

    it 'does not update already backfilled keys' do
      ssh_key_already_backfilled
      deploy_key_already_backfilled

      expect { perform_migration }
        .to not_change { ssh_key_already_backfilled.reload.organization_id }
        .and not_change { deploy_key_already_backfilled.reload.organization_id }
    end

    context 'when deploy key is associated with multiple projects' do
      it 'uses organization_id from the first associated project' do
        namespace3 = table(:namespaces).create!(
          name: 'namespace3',
          path: 'namespace3',
          organization_id: organization2.id
        )

        project3 = table(:projects).create!(
          name: 'project3',
          path: 'project3',
          namespace_id: namespace3.id,
          organization_id: organization2.id,
          project_namespace_id: namespace3.id
        )
        table(:deploy_keys_projects).create!(deploy_key_id: deploy_key1.id, project_id: project3.id)

        expect { perform_migration }
          .to change { deploy_key1.reload.organization_id }.from(nil).to(organization1.id)
      end
    end

    context 'when processing in batches' do
      it 'processes only keys in the specified range' do
        expect do
          described_class.new(
            start_id: ssh_key_with_org1.id,
            end_id: ssh_key_with_org2.id,
            batch_table: :keys,
            batch_column: :id,
            sub_batch_size: 1,
            pause_ms: 0,
            connection: ActiveRecord::Base.connection
          ).perform
        end
          .to change { ssh_key_with_org1.reload.organization_id }.from(nil).to(organization1.id)
          .and change { ssh_key_with_org2.reload.organization_id }.from(nil).to(organization2.id)
          .and not_change { deploy_key1.reload.organization_id }
      end
    end

    context 'when deploy key has no user_id (deploy key specific)' do
      it 'processes deploy keys correctly without user_id' do
        expect(deploy_key1.user_id).to be_nil
        expect { perform_migration }
          .to change { deploy_key1.reload.organization_id }.from(nil).to(organization1.id)
      end
    end

    context 'when SSH key has user_id but deploy key does not' do
      it 'processes both types correctly' do
        expect(ssh_key_with_org1.user_id).to eq(user_with_org1.id)
        expect(deploy_key1.user_id).to be_nil

        expect { perform_migration }
          .to change { ssh_key_with_org1.reload.organization_id }.from(nil).to(organization1.id)
          .and change { deploy_key1.reload.organization_id }.from(nil).to(organization1.id)
      end
    end
  end

  private

  def generate_ssh_key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC#{SecureRandom.base64(368)} test@example.com"
  end
end

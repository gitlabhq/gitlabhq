# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::BackfillOrganizationIdLdapKeys, feature_category: :system_access do
  let!(:default_organization) { table(:organizations).create!(id: 1, path: 'default') }
  let!(:organization1) { table(:organizations).create!(name: 'Organization 1', path: 'org1') }
  let!(:organization2) { table(:organizations).create!(name: 'Organization 2', path: 'org2') }

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

  # LDAPKey records (type: 'LDAPKey'): the target of this BBM
  let!(:ldap_key_with_user_org1) do
    table(:keys).create!(
      title: 'LDAP - ldap_ssh_keys',
      key: generate_ssh_key,
      user_id: user_with_org1.id,
      type: 'LDAPKey',
      organization_id: nil
    )
  end

  let!(:ldap_key_with_user_org2) do
    table(:keys).create!(
      title: 'LDAP - ldap_ssh_keys',
      key: generate_ssh_key,
      user_id: user_with_org2.id,
      type: 'LDAPKey',
      organization_id: nil
    )
  end

  let(:ldap_key_already_backfilled) do
    table(:keys).create!(
      title: 'LDAP - ldap_ssh_keys',
      key: generate_ssh_key,
      user_id: user_with_org1.id,
      type: 'LDAPKey',
      organization_id: organization1.id
    )
  end

  let(:ldap_key_orphaned) do
    table(:keys).create!(
      title: 'LDAP - ldap_ssh_keys',
      key: generate_ssh_key,
      user_id: nil,
      type: 'LDAPKey',
      organization_id: nil
    )
  end

  # Simulates a user_id pointing to a user row that no longer exists
  let(:ldap_key_with_deleted_user) do
    table(:keys).create!(
      title: 'LDAP - ldap_ssh_keys',
      key: generate_ssh_key,
      user_id: non_existing_record_id,
      type: 'LDAPKey',
      organization_id: nil
    )
  end

  # Non-LDAPKey records: should NOT be affected by this BBM
  let!(:ssh_key) do
    table(:keys).create!(
      title: 'SSH Key',
      key: generate_ssh_key,
      user_id: user_with_org1.id,
      type: nil,
      organization_id: nil
    )
  end

  let!(:deploy_key) do
    table(:keys).create!(
      title: 'Deploy Key',
      key: generate_ssh_key,
      user_id: nil,
      type: 'DeployKey',
      organization_id: nil
    )
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

    it 'backfills organization_id for LDAP keys from their owning user' do
      expect { perform_migration }
        .to change { ldap_key_with_user_org1.reload.organization_id }.from(nil).to(organization1.id)
        .and change { ldap_key_with_user_org2.reload.organization_id }.from(nil).to(organization2.id)
    end

    it 'backfills organization_id for orphaned LDAP keys with default organization' do
      ldap_key_orphaned

      expect { perform_migration }
        .to change { ldap_key_orphaned.reload.organization_id }.from(nil).to(1)
    end

    it 'does not update already backfilled LDAP keys' do
      ldap_key_already_backfilled

      expect { perform_migration }
        .to not_change { ldap_key_already_backfilled.reload.organization_id }
    end

    it 'backfills organization_id for LDAP keys whose user has been deleted' do
      ldap_key_with_deleted_user

      expect { perform_migration }
        .to change { ldap_key_with_deleted_user.reload.organization_id }.from(nil).to(1)
    end

    it 'does not affect non-LDAPKey records' do
      expect { perform_migration }
        .to not_change { ssh_key.reload.organization_id }
        .and not_change { deploy_key.reload.organization_id }
    end

    context 'when processing in batches' do
      it 'processes only keys in the specified range' do
        # Create an LDAP key that will be outside the batch range
        out_of_range_ldap_key = table(:keys).create!(
          title: 'LDAP - out of range',
          key: generate_ssh_key,
          user_id: user_with_org1.id,
          type: 'LDAPKey',
          organization_id: nil
        )

        described_class.new(
          start_id: ldap_key_with_user_org1.id,
          end_id: ldap_key_with_user_org2.id,
          batch_table: :keys,
          batch_column: :id,
          sub_batch_size: 100,
          pause_ms: 0,
          connection: ActiveRecord::Base.connection
        ).perform

        expect(ldap_key_with_user_org1.reload.organization_id).to eq(organization1.id)
        expect(ldap_key_with_user_org2.reload.organization_id).to eq(organization2.id)
        expect(out_of_range_ldap_key.reload.organization_id).to be_nil
      end
    end
  end

  private

  def generate_ssh_key
    "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC#{SecureRandom.base64(368)} test@example.com"
  end
end

# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RecalculateTwoFactorEnforcementOnUsers, feature_category: :system_access do
  let(:users_table) { table(:users) }
  let(:organizations_table) { table(:organizations) }
  let(:namespaces_table) { table(:namespaces) }
  let(:members_table) { table(:members) }

  let(:organization) { organizations_table.create!(name: 'Organization', path: 'organization') }

  let!(:group_with_2fa_required) do
    namespaces_table.create!(
      name: 'Group with 2FA',
      path: 'group-2fa',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: true,
      two_factor_grace_period: 3
    )
  end

  let!(:group_without_2fa) do
    namespaces_table.create!(
      name: 'Group without 2FA',
      path: 'group-no-2fa',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: false
    )
  end

  let!(:user_in_2fa_group) do
    users_table.create!(
      name: 'user1',
      email: 'user1@gitlab.com',
      projects_limit: 5,
      organization_id: organization.id,
      require_two_factor_authentication_from_group: false
    ).tap do |user|
      members_table.create!(
        user_id: user.id,
        source_id: group_with_2fa_required.id,
        source_type: 'Namespace',
        type: 'GroupMember',
        access_level: 30,
        notification_level: 3,
        member_namespace_id: group_with_2fa_required.id
      )
    end
  end

  let!(:user_without_2fa_groups) do
    users_table.create!(
      name: 'user2',
      email: 'user2@gitlab.com',
      projects_limit: 5,
      organization_id: organization.id,
      require_two_factor_authentication_from_group: false
    ).tap do |user|
      members_table.create!(
        user_id: user.id,
        source_id: group_without_2fa.id,
        source_type: 'Namespace',
        type: 'GroupMember',
        access_level: 30,
        notification_level: 3,
        member_namespace_id: group_without_2fa.id
      )
    end
  end

  let!(:user_with_inconsistent_2fa_enforcement) do
    users_table.create!(
      name: 'user3',
      email: 'user3@gitlab.com',
      projects_limit: 5,
      organization_id: organization.id,
      require_two_factor_authentication_from_group: true
    ).tap do |user|
      members_table.create!(
        user_id: user.id,
        source_id: group_without_2fa.id,
        source_type: 'Namespace',
        type: 'GroupMember',
        access_level: 30,
        notification_level: 3,
        member_namespace_id: group_without_2fa.id
      )
    end
  end

  let!(:bot_user) do
    users_table.create!(
      name: 'bot',
      email: 'bot@gitlab.com',
      projects_limit: 5,
      organization_id: organization.id,
      user_type: 6,
      require_two_factor_authentication_from_group: false
    ).tap do |user|
      members_table.create!(
        user_id: user.id,
        source_id: group_with_2fa_required.id,
        source_type: 'Namespace',
        type: 'GroupMember',
        access_level: 30,
        notification_level: 3,
        member_namespace_id: group_with_2fa_required.id
      )
    end
  end

  describe '#perform' do
    subject(:perform_migration) do
      described_class.new(
        batch_table: :users,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      ).perform
    end

    it 'updates 2FA enforcement for user in 2FA group' do
      expect { perform_migration }.to change {
        user_in_2fa_group.reload.require_two_factor_authentication_from_group
      }.from(false).to(true)

      expect(user_in_2fa_group.two_factor_grace_period).to eq 3
    end

    it 'does not change 2FA enforcement for user without 2FA group', :aggregate_failures do
      expect { perform_migration }.not_to change {
        user_without_2fa_groups.reload.require_two_factor_authentication_from_group
      }.from(false)
    end

    it 'updates 2FA enforcement if incorrectly enforced' do
      expect { perform_migration }.to change {
        user_with_inconsistent_2fa_enforcement.reload.require_two_factor_authentication_from_group
      }.from(true).to(false)
    end

    it 'does not update bot users enforcement' do
      expect { perform_migration }.not_to change {
        bot_user.reload.require_two_factor_authentication_from_group
      }.from(false)
    end

    it 'logs the change' do
      expect(Gitlab::AppLogger).to(
        receive(:info).with({
          message: 'User 2FA enforcement from group changed.',
          user_id: user_in_2fa_group.id,
          from: false,
          to: true
        }))
      expect(Gitlab::AppLogger).to(
        receive(:info).with({
          message: 'User 2FA enforcement from group changed.',
          user_id: user_with_inconsistent_2fa_enforcement.id,
          from: true,
          to: false
        }))

      perform_migration
    end
  end
end

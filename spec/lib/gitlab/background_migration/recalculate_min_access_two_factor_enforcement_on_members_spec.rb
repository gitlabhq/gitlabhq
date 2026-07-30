# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RecalculateMinAccessTwoFactorEnforcementOnMembers, feature_category: :system_access do
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
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:group_without_2fa) do
    namespaces_table.create!(
      name: 'Group without 2FA',
      path: 'group-no-2fa',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: false
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:root_without_2fa_enforcement) do
    namespaces_table.create!(
      name: 'Root without 2FA',
      path: 'root-without-2fa',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: false
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:descendant_subgroup_enforcing_2fa) do
    namespaces_table.create!(
      name: 'Descendant subgroup with 2FA',
      path: 'descendant-subgroup-2fa',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: true,
      two_factor_grace_period: 7,
      parent_id: root_without_2fa_enforcement.id
    ).tap do |namespace|
      namespace.update!(traversal_ids: [root_without_2fa_enforcement.id, namespace.id])
    end
  end

  let!(:root_with_2fa_enforcement) do
    namespaces_table.create!(
      name: 'Root with 2FA',
      path: 'root-with-2fa',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: true,
      two_factor_grace_period: 30
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:descendant_subgroup_with_shorter_grace_period) do
    namespaces_table.create!(
      name: 'Descendant subgroup with shorter grace period',
      path: 'descendant-subgroup-shorter-grace',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: true,
      two_factor_grace_period: 7,
      parent_id: root_with_2fa_enforcement.id
    ).tap do |namespace|
      namespace.update!(traversal_ids: [root_with_2fa_enforcement.id, namespace.id])
    end
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
        access_level: 5,
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
        access_level: 5,
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
        access_level: 5,
        notification_level: 3,
        member_namespace_id: group_without_2fa.id
      )
    end
  end

  # All but this user, have a minimal_access_role(5)
  let!(:user_in_2fa_group_with_greater_than_minimal_access) do
    users_table.create!(
      name: 'user4',
      email: 'user4@gitlab.com',
      projects_limit: 5,
      organization_id: organization.id,
      require_two_factor_authentication_from_group: false
    ).tap do |user|
      members_table.create!(
        user_id: user.id,
        source_id: group_with_2fa_required.id,
        source_type: 'Namespace',
        type: 'GroupMember',
        access_level: 10,
        notification_level: 3,
        member_namespace_id: group_with_2fa_required.id
      )
    end
  end

  let!(:minimal_access_user_at_root) do
    users_table.create!(
      name: 'min_access_root_user',
      email: 'min_access_root_user@gitlab.com',
      projects_limit: 5,
      organization_id: organization.id,
      require_two_factor_authentication_from_group: true,
      two_factor_grace_period: 7
    ).tap do |user|
      members_table.create!(
        user_id: user.id,
        source_id: root_without_2fa_enforcement.id,
        source_type: 'Namespace',
        type: 'GroupMember',
        access_level: 5,
        notification_level: 3,
        member_namespace_id: root_without_2fa_enforcement.id
      )
    end
  end

  let!(:minimal_access_user_with_long_grace_period) do
    users_table.create!(
      name: 'min_access_user_long_grace',
      email: 'min_access_user_long_grace@gitlab.com',
      projects_limit: 5,
      organization_id: organization.id,
      require_two_factor_authentication_from_group: false,
      two_factor_grace_period: 48
    ).tap do |user|
      members_table.create!(
        user_id: user.id,
        source_id: root_with_2fa_enforcement.id,
        source_type: 'Namespace',
        type: 'GroupMember',
        access_level: 5,
        notification_level: 3,
        member_namespace_id: root_with_2fa_enforcement.id
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
        access_level: 5,
        notification_level: 3,
        member_namespace_id: group_with_2fa_required.id
      )
    end
  end

  describe '#perform' do
    subject(:perform_migration) do
      described_class.new(
        batch_table: :members,
        batch_column: :id,
        sub_batch_size: 2,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      ).perform
    end

    context 'with human users' do
      context 'when in top-level-groups' do
        context 'with minimal_access_role' do
          it 'updates 2FA enforcement for minimal_access_user in 2FA group' do
            expect { perform_migration }.to change {
              user_in_2fa_group.reload.require_two_factor_authentication_from_group
            }.from(false).to(true)

            expect(user_in_2fa_group.two_factor_grace_period).to eq 3
          end

          it 'updates 2FA enforcement for minimal_access_user, if incorrectly enforced' do
            expect { perform_migration }.to change {
              user_with_inconsistent_2fa_enforcement.reload.require_two_factor_authentication_from_group
            }.from(true).to(false)
          end

          it 'does not update 2FA enforcement for user without 2FA group' do
            expect { perform_migration }.not_to change {
              user_without_2fa_groups.reload.require_two_factor_authentication_from_group
            }
          end
        end

        context 'without minimal_access_role' do
          it 'does not update 2FA enforcement for user with a greater than minimal access level, in a 2FA group' do
            expect { perform_migration }.not_to change {
              user_in_2fa_group_with_greater_than_minimal_access.reload.require_two_factor_authentication_from_group
            }
          end
        end
      end

      context 'when the root does not enforce 2FA but a descendant subgroup does' do
        it 'does not disable 2FA enforcement required by the descendant subgroup' do
          expect { perform_migration }.not_to change {
            minimal_access_user_at_root.reload.require_two_factor_authentication_from_group
          }.from(true)
        end
      end

      context 'when the root enforces 2FA and a descendant subgroup has a shorter grace period' do
        it 'sets the shortest grace period from the hierarchy' do
          perform_migration

          minimal_access_user_with_long_grace_period.reload

          expect(minimal_access_user_with_long_grace_period.two_factor_grace_period).to eq(7)
          expect(minimal_access_user_with_long_grace_period.require_two_factor_authentication_from_group).to be(true)
        end
      end
    end

    context 'with bot_users' do
      it 'does not update 2FA enforcement for minimal_access bot_user' do
        expect { perform_migration }.not_to change {
          bot_user.reload.require_two_factor_authentication_from_group
        }
      end
    end

    it 'logs updates of updated minimal_access_users within 2FA enforced groups' do
      expect(Gitlab::AppLogger).to(
        receive(:info).with({
          message: 'Minimal_access user group 2FA enforcement changed.',
          Labkit::Fields::GL_USER_ID => user_in_2fa_group.id,
          from: false,
          to: true
        }))
      expect(Gitlab::AppLogger).to(
        receive(:info).with({
          message: 'Minimal_access user group 2FA enforcement changed.',
          Labkit::Fields::GL_USER_ID => user_with_inconsistent_2fa_enforcement.id,
          from: true,
          to: false
        }))
      expect(Gitlab::AppLogger).to(
        receive(:info).with({
          message: 'Minimal_access user group 2FA enforcement changed.',
          Labkit::Fields::GL_USER_ID => minimal_access_user_with_long_grace_period.id,
          from: false,
          to: true
        }))

      perform_migration
    end
  end
end

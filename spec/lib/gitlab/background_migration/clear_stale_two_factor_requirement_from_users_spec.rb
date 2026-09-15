# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::ClearStaleTwoFactorRequirementFromUsers, feature_category: :system_access do
  let(:users_table) { table(:users) }
  let(:organizations_table) { table(:organizations) }
  let(:namespaces_table) { table(:namespaces) }
  let(:members_table) { table(:members) }

  let(:organization) { organizations_table.create!(name: 'Organization', path: 'organization') }

  let!(:group_without_2fa) do
    namespaces_table.create!(
      name: 'Group without 2FA',
      path: 'group-no-2fa',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: false
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:group_with_2fa) do
    namespaces_table.create!(
      name: 'Group with 2FA',
      path: 'group-2fa',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: true,
      two_factor_grace_period: 3
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:root_with_enforcing_subgroup) do
    namespaces_table.create!(
      name: 'Root with enforcing subgroup',
      path: 'root-enforcing-subgroup',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: false
    ).tap { |namespace| namespace.update!(traversal_ids: [namespace.id]) }
  end

  let!(:enforcing_subgroup) do
    namespaces_table.create!(
      name: 'Enforcing subgroup',
      path: 'enforcing-subgroup',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: true,
      two_factor_grace_period: 7,
      parent_id: root_with_enforcing_subgroup.id
    ).tap do |namespace|
      namespace.update!(traversal_ids: [root_with_enforcing_subgroup.id, namespace.id])
    end
  end

  let!(:stale_minimal_access_user) do
    create_user('stale-minimal', require_two_factor_authentication_from_group: true, two_factor_grace_period: 0)
      .tap { |user| create_member(user, group_without_2fa, access_level: 5) }
  end

  let!(:stale_promoted_user) do
    create_user('stale-promoted', require_two_factor_authentication_from_group: true).tap do |user|
      create_member(user, group_without_2fa, access_level: 50)
    end
  end

  let!(:stale_removed_user) do
    create_user('stale-removed', require_two_factor_authentication_from_group: true, two_factor_grace_period: 0)
  end

  let!(:subgroup_under_enforcing_root) do
    namespaces_table.create!(
      name: 'Subgroup under enforcing root',
      path: 'subgroup-under-enforcing-root',
      type: 'Group',
      organization_id: organization.id,
      require_two_factor_authentication: false,
      parent_id: group_with_2fa.id
    ).tap do |namespace|
      namespace.update!(traversal_ids: [group_with_2fa.id, namespace.id])
    end
  end

  let!(:user_with_pending_request_to_enforcing_group) do
    create_user('stale-requester', require_two_factor_authentication_from_group: true).tap do |user|
      create_member(user, group_with_2fa, access_level: 30, requested_at: Time.current)
    end
  end

  let!(:user_enforced_via_root) do
    create_user('enforced-via-root', require_two_factor_authentication_from_group: true).tap do |user|
      create_member(user, subgroup_under_enforcing_root, access_level: 30)
    end
  end

  let!(:user_with_enforcing_minimal_access_hierarchy) do
    create_user('enforced-minimal', require_two_factor_authentication_from_group: true).tap do |user|
      create_member(user, root_with_enforcing_subgroup, access_level: 5)
    end
  end

  let!(:user_with_enforcing_regular_membership) do
    create_user('enforced-developer', require_two_factor_authentication_from_group: true).tap do |user|
      create_member(user, group_without_2fa, access_level: 5)
      create_member(user, group_with_2fa, access_level: 30)
    end
  end

  let!(:user_without_requirement) do
    create_user('unflagged', require_two_factor_authentication_from_group: false).tap do |user|
      create_member(user, group_without_2fa, access_level: 5)
    end
  end

  let!(:bot_user) do
    create_user('bot', require_two_factor_authentication_from_group: true, user_type: 6).tap do |user|
      create_member(user, group_without_2fa, access_level: 5)
    end
  end

  describe '#perform' do
    subject(:perform_migration) do
      described_class.new(
        batch_table: :users,
        batch_column: :id,
        sub_batch_size: 100,
        pause_ms: 0,
        connection: ApplicationRecord.connection
      ).perform
    end

    context 'with users carrying a stale requirement' do
      it 'clears the requirement for a minimal access user and resets the grace period' do
        expect { perform_migration }.to change {
          stale_minimal_access_user.reload.require_two_factor_authentication_from_group
        }.from(true).to(false)

        expect(stale_minimal_access_user.two_factor_grace_period).to eq(48)
      end

      it 'clears the requirement for a user whose membership no longer has minimal access' do
        expect { perform_migration }.to change {
          stale_promoted_user.reload.require_two_factor_authentication_from_group
        }.from(true).to(false)
      end

      it 'clears the requirement for a user without any remaining membership' do
        expect { perform_migration }.to change {
          stale_removed_user.reload.require_two_factor_authentication_from_group
        }.from(true).to(false)
      end

      it 'clears the requirement when the only tie to an enforcing group is an access request' do
        expect { perform_migration }.to change {
          user_with_pending_request_to_enforcing_group.reload.require_two_factor_authentication_from_group
        }.from(true).to(false)
      end

      it 'logs each cleared user' do
        expect(Gitlab::AppLogger).to receive(:info).with(
          hash_including(
            message: 'Stale user group 2FA enforcement cleared.',
            Labkit::Fields::GL_USER_ID => stale_minimal_access_user.id
          )
        )
        expect(Gitlab::AppLogger).to receive(:info)
          .with(hash_including(Labkit::Fields::GL_USER_ID => stale_promoted_user.id))
        expect(Gitlab::AppLogger).to receive(:info)
          .with(hash_including(Labkit::Fields::GL_USER_ID => stale_removed_user.id))
        expect(Gitlab::AppLogger).to receive(:info)
          .with(hash_including(Labkit::Fields::GL_USER_ID => user_with_pending_request_to_enforcing_group.id))

        perform_migration
      end
    end

    context 'with users whose requirement is still enforced' do
      it 'keeps the requirement when a group in the minimal access hierarchy enforces 2FA' do
        expect { perform_migration }.not_to change {
          user_with_enforcing_minimal_access_hierarchy.reload.require_two_factor_authentication_from_group
        }.from(true)
      end

      it 'keeps the requirement and grace period when another membership provides the enforcement' do
        expect { perform_migration }.to not_change {
          user_with_enforcing_regular_membership.reload.require_two_factor_authentication_from_group
        }.and not_change { user_with_enforcing_regular_membership.reload.two_factor_grace_period }
      end

      it 'keeps the requirement for subgroup members when the root group enforces 2FA' do
        expect { perform_migration }.not_to change {
          user_enforced_via_root.reload.require_two_factor_authentication_from_group
        }.from(true)
      end
    end

    context 'with users outside the migration scope' do
      it 'does not touch users without the requirement' do
        expect { perform_migration }.not_to change {
          user_without_requirement.reload.attributes
        }
      end

      it 'does not touch non-human users' do
        expect { perform_migration }.not_to change {
          bot_user.reload.require_two_factor_authentication_from_group
        }.from(true)
      end
    end
  end

  private

  def create_user(name, **attributes)
    users_table.create!(
      name: name,
      email: "#{name}@example.com",
      projects_limit: 5,
      organization_id: organization.id,
      **attributes
    )
  end

  def create_member(user, group, access_level:, requested_at: nil)
    members_table.create!(
      user_id: user.id,
      source_id: group.id,
      source_type: 'Namespace',
      type: 'GroupMember',
      access_level: access_level,
      notification_level: 3,
      member_namespace_id: group.id,
      requested_at: requested_at
    )
  end
end

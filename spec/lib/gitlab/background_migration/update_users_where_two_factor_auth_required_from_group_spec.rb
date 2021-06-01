# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::UpdateUsersWhereTwoFactorAuthRequiredFromGroup, :migration, schema: 20210519154058 do
  include MigrationHelpers::NamespacesHelpers

  let(:group_with_2fa_parent) { create_namespace('parent', Gitlab::VisibilityLevel::PRIVATE, require_two_factor_authentication: true) }
  let(:group_with_2fa_child) { create_namespace('child', Gitlab::VisibilityLevel::PRIVATE, parent_id: group_with_2fa_parent.id) }
  let(:members_table) { table(:members) }
  let(:users_table) { table(:users) }

  subject { described_class.new }

  describe '#perform' do
    context 'with group members' do
      let(:user_1) { create_user('user@example.com') }
      let!(:member) { create_group_member(user_1, group_with_2fa_parent) }
      let!(:user_without_group) { create_user('user_without@example.com') }
      let(:user_other) { create_user('user_other@example.com') }
      let!(:member_other) { create_group_member(user_other, group_with_2fa_parent) }

      it 'updates user when user should be required to establish two factor authentication' do
        subject.perform(user_1.id, user_without_group.id)

        expect(user_1.reload.require_two_factor_authentication_from_group).to eq(true)
      end

      it 'does not update user who is not in current batch' do
        subject.perform(user_1.id, user_without_group.id)

        expect(user_other.reload.require_two_factor_authentication_from_group).to eq(false)
      end

      it 'updates all users in current batch' do
        subject.perform(user_1.id, user_other.id)

        expect(user_other.reload.require_two_factor_authentication_from_group).to eq(true)
      end

      it 'updates user when user is member of group in which parent group requires two factor authentication' do
        member.destroy!

        subgroup = create_namespace('subgroup', Gitlab::VisibilityLevel::PRIVATE, require_two_factor_authentication: false, parent_id: group_with_2fa_child.id)
        create_group_member(user_1, subgroup)

        subject.perform(user_1.id, user_other.id)

        expect(user_1.reload.require_two_factor_authentication_from_group).to eq(true)
      end

      it 'updates user when user is member of a group and the subgroup requires two factor authentication' do
        member.destroy!

        parent = create_namespace('other_parent', Gitlab::VisibilityLevel::PRIVATE, require_two_factor_authentication: false)
        create_namespace('other_subgroup', Gitlab::VisibilityLevel::PRIVATE, require_two_factor_authentication: true, parent_id: parent.id)
        create_group_member(user_1, parent)

        subject.perform(user_1.id, user_other.id)

        expect(user_1.reload.require_two_factor_authentication_from_group).to eq(true)
      end

      it 'does not update user when not a member of a group that requires two factor authentication' do
        member_other.destroy!

        other_group = create_namespace('other_group', Gitlab::VisibilityLevel::PRIVATE, require_two_factor_authentication: false)
        create_group_member(user_other, other_group)

        subject.perform(user_1.id, user_other.id)

        expect(user_other.reload.require_two_factor_authentication_from_group).to eq(false)
      end
    end
  end

  def create_user(email, require_2fa: false)
    users_table.create!(email: email, projects_limit: 10, require_two_factor_authentication_from_group: require_2fa)
  end

  def create_group_member(user, group)
    members_table.create!(user_id: user.id, source_id: group.id, access_level: GroupMember::MAINTAINER, source_type: "Namespace", type: "GroupMember", notification_level: 3)
  end
end

# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DeleteOrphanedUserGroupMemberRoles, :migration, feature_category: :permissions do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:organizations) { table(:organizations) }
  let(:members) { table(:members) }
  let(:group_group_links) { table(:group_group_links) }
  let(:member_roles) { table(:member_roles) }
  let(:user_group_member_roles) { table(:user_group_member_roles) }

  let(:organization) { organizations.create!(name: 'Organization 1', path: 'organization-1') }

  let(:group_1) do
    namespaces.create!(name: 'G1', path: 'group-1', organization_id: organization.id)
  end

  let(:group_2) do
    namespaces.create!(name: 'G2', path: 'group-2', organization_id: organization.id)
  end

  let(:group_3) do
    namespaces.create!(name: 'G3', path: 'group-3', organization_id: organization.id)
  end

  let!(:user) do
    users.create!(name: 'test-1', email: 'test@example.com', projects_limit: 5, organization_id: organization.id)
  end

  let(:member_role) do
    member_roles.create!(name: 'Custom role', base_access_level: Gitlab::Access::GUEST)
  end

  let!(:group_1_member) do
    members.create!(
      access_level: 10,
      source_id: group_1.id,
      source_type: "Namespace",
      user_id: user.id,
      state: 0,
      notification_level: 3,
      type: "GroupMember",
      member_namespace_id: group_1.id,
      member_role_id: member_role.id
    )
  end

  let!(:group_2_member) do
    members.create!(
      access_level: 10,
      source_id: group_2.id,
      source_type: "Namespace",
      user_id: user.id,
      state: 0,
      notification_level: 3,
      type: "GroupMember",
      member_namespace_id: group_2.id
    )
  end

  let!(:group_link) do
    group_group_links.create!(
      shared_group_id: group_1.id,
      shared_with_group_id: group_2.id,
      group_access: Gitlab::Access::GUEST,
      member_role_id: member_role.id
    )
  end

  # Member role assignment through direct group membership
  let!(:user_group_member_role_1) do
    user_group_member_roles.create!(
      user_id: user.id,
      group_id: group_1.id,
      member_role_id: member_role.id,
      shared_with_group_id: nil
    )
  end

  # Member role assignment through group sharing
  let!(:user_group_member_role_2) do
    user_group_member_roles.create!(
      user_id: user.id,
      group_id: group_1.id,
      member_role_id: member_role.id,
      shared_with_group_id: group_2.id
    )
  end

  # Orphan member role assignment through direct group membership -
  # member.member_role_id was set to nil but the matching
  # user_group_member_roles was not deleted
  let!(:orphan_user_group_member_role_1) do
    user_group_member_roles.create!(
      user_id: user.id,
      group_id: group_2.id,
      member_role_id: member_role.id,
      shared_with_group_id: nil
    )
  end

  # Orphan member role assignment through direct group membership - member
  # record was deleted but matching the user_group_member_roles was not deleted
  let!(:orphan_user_group_member_role_2) do
    user_group_member_roles.create!(
      user_id: user.id,
      group_id: group_3.id,
      member_role_id: member_role.id,
      shared_with_group_id: nil
    )
  end

  it 'removes only orphaned user_group_member_roles', :aggregate_failures do
    migrate!

    expect(user_group_member_roles.find(user_group_member_role_1.id)).not_to be_nil
    expect(user_group_member_roles.find(user_group_member_role_2.id)).not_to be_nil

    expect(user_group_member_roles.find_by(id: orphan_user_group_member_role_1.id)).to be_nil
    expect(user_group_member_roles.find_by(id: orphan_user_group_member_role_2.id)).to be_nil
  end
end

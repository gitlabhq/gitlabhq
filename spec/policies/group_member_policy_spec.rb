# frozen_string_literal: true

require 'spec_helper'

describe GroupMemberPolicy do
  let(:guest) { create(:user) }
  let(:owner) { create(:user) }
  let(:group) { create(:group, :private) }

  before do
    group.add_guest(guest)
    group.add_owner(owner)
  end

  let(:member_related_permissions) do
    [:update_group_member, :destroy_group_member]
  end

  let(:membership) { current_user.members.first }

  subject { described_class.new(current_user, membership) }

  def expect_allowed(*permissions)
    permissions.each { |p| is_expected.to be_allowed(p) }
  end

  def expect_disallowed(*permissions)
    permissions.each { |p| is_expected.not_to be_allowed(p) }
  end

  context 'with guest user' do
    let(:current_user) { guest }

    it do
      expect_disallowed(:member_related_permissions)
    end
  end

  context 'with one owner' do
    let(:current_user) { owner }

    it do
      expect_disallowed(:destroy_group_member)
      expect_disallowed(:update_group_member)
    end
  end

  context 'with more than one owner' do
    let(:current_user) { owner }

    before do
      group.add_owner(create(:user))
    end

    it do
      expect_allowed(:destroy_group_member)
      expect_allowed(:update_group_member)
    end
  end

  context 'with the group parent' do
    let(:current_user) { create :user }
    let(:subgroup) { create(:group, :private, parent: group)}

    before do
      group.add_owner(owner)
      subgroup.add_owner(current_user)
    end

    it do
      expect_allowed(:destroy_group_member)
      expect_allowed(:update_group_member)
    end
  end

  context 'without group parent' do
    let(:current_user) { create :user }
    let(:subgroup) { create(:group, :private)}

    before do
      subgroup.add_owner(current_user)
    end

    it do
      expect_disallowed(:destroy_group_member)
      expect_disallowed(:update_group_member)
    end
  end

  context 'without group parent with two owners' do
    let(:current_user) { create :user }
    let(:other_user) { create :user }
    let(:subgroup) { create(:group, :private)}

    before do
      subgroup.add_owner(current_user)
      subgroup.add_owner(other_user)
    end

    it do
      expect_allowed(:destroy_group_member)
      expect_allowed(:update_group_member)
    end
  end
end

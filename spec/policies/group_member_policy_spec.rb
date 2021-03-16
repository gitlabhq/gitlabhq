# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupMemberPolicy do
  include DesignManagementTestHelpers

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

  context 'with anonymous user' do
    let(:group) { create(:group, :public) }
    let(:current_user) { nil }
    let(:membership) { guest.members.first }

    it do
      expect_disallowed(:read_design_activity, *member_related_permissions)
      expect_allowed(:read_group)
    end

    context 'design management is enabled' do
      before do
        create(:project, :public, group: group) # Necessary to enable design management
        enable_design_management
      end

      specify do
        expect_allowed(:read_design_activity)
      end
    end

    context 'for a private group' do
      let(:group) { create(:group, :private) }

      specify do
        expect_disallowed(:read_group, :read_design_activity, *member_related_permissions)
      end
    end

    context 'for an internal group' do
      let(:group) { create(:group, :internal) }

      specify do
        expect_disallowed(:read_group, :read_design_activity, *member_related_permissions)
      end
    end
  end

  context 'with guest user, for own membership' do
    let(:current_user) { guest }

    specify { expect_disallowed(:update_group_member) }
    specify { expect_allowed(:read_group, :destroy_group_member) }
  end

  context 'with guest user, for other membership' do
    let(:current_user) { guest }
    let(:membership) { owner.members.first }

    specify { expect_disallowed(:destroy_group_member, :update_group_member) }
    specify { expect_allowed(:read_group) }
  end

  context 'with one owner' do
    let(:current_user) { owner }

    specify { expect_disallowed(*member_related_permissions) }
    specify { expect_allowed(:read_group) }
  end

  context 'with one blocked owner' do
    let(:owner) { create(:user, :blocked) }
    let(:current_user) { owner }

    specify { expect_disallowed(*member_related_permissions) }
    specify { expect_disallowed(:read_group) }
  end

  context 'with more than one owner' do
    let(:current_user) { owner }

    before do
      group.add_owner(create(:user))
    end

    specify { expect_allowed(*member_related_permissions) }
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

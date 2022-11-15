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

  context 'for access requests' do
    let_it_be(:group) { create(:group, :public) }
    let_it_be(:user) { create(:user) }

    let(:current_user) { user }

    context 'for own access request' do
      let(:membership) { create(:group_member, :access_request, group: group, user: user) }

      specify { expect_allowed(:withdraw_member_access_request) }
    end

    context "for another user's access request" do
      let(:membership) { create(:group_member, :access_request, group: group, user: create(:user)) }

      specify { expect_disallowed(:withdraw_member_access_request) }
    end

    context 'for own, valid membership' do
      let(:membership) { create(:group_member, :developer, group: group, user: user) }

      specify { expect_disallowed(:withdraw_member_access_request) }
    end
  end

  context 'with bot user' do
    let(:current_user) { create(:user, :project_bot) }

    before do
      group.add_owner(current_user)
    end

    specify { expect_allowed(:read_group, :destroy_project_bot_member) }
  end

  context 'with anonymous bot user' do
    let(:current_user) { create(:user, :project_bot) }
    let(:membership) { guest.members.first }

    specify { expect_disallowed(:read_group, :destroy_project_bot_member) }
  end

  context 'with owner' do
    let(:current_user) { owner }

    context 'with group with one owner' do
      specify { expect_disallowed(*member_related_permissions) }
      specify { expect_allowed(:read_group) }
    end

    context 'with group with bot user owner' do
      before do
        group.add_owner(create(:user, :project_bot))
      end

      specify { expect_disallowed(*member_related_permissions) }
    end

    context 'with group with more than one owner' do
      before do
        group.add_owner(create(:user))
      end

      specify { expect_allowed(*member_related_permissions) }
      specify { expect_disallowed(:destroy_project_bot_member) }
    end

    context 'with group with owners from a parent' do
      context 'when top-level group' do
        context 'with group sharing' do
          let!(:subgroup) { create(:group, :private, parent: group) }

          before do
            create(:group_group_link, :owner, shared_group: group, shared_with_group: subgroup)
            create(:group_member, :owner, group: subgroup)
          end

          specify { expect_disallowed(*member_related_permissions) }
          specify { expect_allowed(:read_group) }
        end
      end

      context 'when subgroup' do
        let(:current_user) { create :user }

        let!(:subgroup) { create(:group, :private, parent: group) }

        before do
          subgroup.add_owner(current_user)
        end

        specify { expect_allowed(*member_related_permissions) }
        specify { expect_allowed(:read_group) }
      end
    end
  end

  context 'with blocked owner' do
    let(:owner) { create(:user, :blocked) }
    let(:current_user) { owner }

    specify { expect_disallowed(*member_related_permissions) }
    specify { expect_disallowed(:read_group) }

    context 'with group with bot user owner' do
      before do
        group.add_owner(create(:user, :project_bot))
      end

      specify { expect_disallowed(*member_related_permissions) }
      specify { expect_disallowed(:read_group) }
    end

    context 'with group with more than one blocked owner' do
      before do
        group.add_owner(create(:user, :blocked))
      end

      specify { expect_allowed(:destroy_group_member) }
    end
  end
end

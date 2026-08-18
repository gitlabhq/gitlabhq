# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/two_factor_auths/_groups_notification.html.haml', feature_category: :system_access do
  let_it_be(:user) { create(:user) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  def render_notification(groups)
    memberships = GroupMember.with_user(user).with_source_id(groups.map(&:id)).index_by(&:source_id)
    render partial: 'profiles/two_factor_auths/groups_notification',
      locals: { groups: groups, memberships: memberships }
  end

  context 'with a single group the user can leave' do
    let_it_be(:group) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check

    before_all do
      group.add_developer(user)
    end

    it 'renders the group behind a disclosure with a leave link' do
      render_notification([group])

      expect(rendered).to have_css("[data-testid='two-factor-groups-notification-details'] summary",
        text: 'Review and leave groups')
      expect(rendered).to have_css("[data-testid='two-factor-groups-notification'] > li", count: 1, visible: :all)
      expect(rendered).to have_link(group.full_name, href: group_path(group), visible: :all)
      expect(rendered).to have_css(
        "[data-testid='leave-group-link'][href='#{leave_group_members_path(group)}']",
        text: 'Leave group', visible: :all
      )
    end
  end

  context 'with multiple groups the user can leave' do
    let_it_be(:groups) { create_list(:group, 5) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check

    before_all do
      groups.each { |group| group.add_developer(user) }
    end

    it 'renders every group with its own leave link' do
      render_notification(groups)

      expect(rendered).to have_css("[data-testid='two-factor-groups-notification'] > li", count: 5, visible: :all)
      groups.each do |group|
        expect(rendered).to have_link(group.full_name, href: group_path(group), visible: :all)
        expect(rendered).to have_css(
          "[data-testid='leave-group-link'][href='#{leave_group_members_path(group)}']",
          text: 'Leave group', visible: :all
        )
      end
    end
  end

  context 'when the user is the sole owner of a group' do
    let_it_be(:group) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check

    before_all do
      group.add_owner(user)
    end

    it 'renders an explanation instead of a leave link' do
      render_notification([group])

      expect(rendered).to have_link(group.full_name, href: group_path(group), visible: :all)
      expect(rendered).not_to have_css("[data-testid='leave-group-link']", visible: :all)
      expect(rendered).to have_css("[data-testid='leave-group-blocked']", text: 'You are the last owner', visible: :all)
    end
  end
end

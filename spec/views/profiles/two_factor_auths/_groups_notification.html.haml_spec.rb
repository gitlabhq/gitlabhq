# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'profiles/two_factor_auths/_groups_notification.html.haml', feature_category: :system_access do
  let_it_be(:user) { create(:user) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check

  before do
    allow(view).to receive(:current_user).and_return(user)
  end

  def render_notification(groups)
    memberships = GroupMember.with_user(user).with_source_id(groups.map(&:id)).index_by(&:source_id)
    leavable = groups.any? { |group| user.can?(:destroy_group_member, memberships[group.id]) }
    render partial: 'profiles/two_factor_auths/groups_notification',
      locals: { groups: groups, memberships: memberships, leavable: leavable }
  end

  context 'with a single group the user can leave' do
    let_it_be(:group) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check

    before_all do
      group.add_developer(user)
    end

    it 'renders the group behind a disclosure with a leave button' do
      render_notification([group])

      expect(rendered).to have_css("[data-testid='two-factor-groups-notification-details'] summary",
        text: _('Review and leave groups'))
      expect(rendered).to have_css("[data-testid='two-factor-groups-notification'] > li", count: 1, visible: :all)
      expect(rendered).to have_text(group.name)
      expect(rendered).not_to have_link(group.name, href: group_path(group), visible: :all)
      expect(rendered).to have_css(
        "[data-testid='two-factor-leave-group-button'][href='#{leave_group_members_path(group)}']",
        text: _('Leave group'), visible: :all
      )
    end

    it 'confirms leaving through a modal before the delete goes out' do
      render_notification([group])

      expect(rendered).to have_css(
        "[data-testid='two-factor-leave-group-button']" \
          "[data-method='delete']" \
          "[data-confirm-btn-variant='danger']" \
          "[data-confirm='#{format(s_('GroupsTree|Are you sure you want to leave \"%{fullName}\"?'),
            fullName: group.full_name)}']",
        visible: :all
      )
    end
  end

  context 'with multiple groups the user can leave' do
    let_it_be(:groups) { create_list(:group, 5) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check

    before_all do
      groups.each { |group| group.add_developer(user) }
    end

    it 'renders every group with its own leave button' do
      render_notification(groups)

      expect(rendered).to have_css("[data-testid='two-factor-groups-notification'] > li", count: 5, visible: :all)
      groups.each do |group|
        expect(rendered).to have_text(group.name)
        expect(rendered).to have_css(
          "[data-testid='two-factor-leave-group-button'][href='#{leave_group_members_path(group)}']",
          text: _('Leave group'), visible: :all
        )
      end
    end
  end

  context 'when the user is the sole owner of a group' do
    let_it_be(:group) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check

    before_all do
      group.add_owner(user)
    end

    it 'renders an explanation instead of a leave button' do
      render_notification([group])

      expect(rendered).to have_text(group.name)
      expect(rendered).not_to have_css("[data-testid='two-factor-leave-group-button']", visible: :all)
      expect(rendered).to have_css("[data-testid='leave-group-blocked']", text: _('You cannot leave this group'),
        visible: :all)
    end

    it 'drops leaving from the disclosure label' do
      render_notification([group])

      expect(rendered).to have_css("[data-testid='two-factor-groups-notification-details'] summary",
        text: _('Review groups'))
    end
  end

  context 'when only some of the groups can be left' do
    let_it_be(:leavable_group) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check
    let_it_be(:sole_owned_group) { create(:group) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check

    before_all do
      leavable_group.add_developer(user)
      sole_owned_group.add_owner(user)
    end

    it 'still offers leaving, and blocks only the group that cannot be left' do
      render_notification([leavable_group, sole_owned_group])

      expect(rendered).to have_css("[data-testid='two-factor-groups-notification-details'] summary",
        text: _('Review and leave groups'))
      expect(rendered).to have_css(
        "[data-testid='two-factor-leave-group-button'][href='#{leave_group_members_path(leavable_group)}']",
        count: 1, visible: :all
      )
      expect(rendered).to have_css("[data-testid='leave-group-blocked']", count: 1, visible: :all)
    end
  end

  # A top-level group's name and full name are identical, so only a subgroup can tell the two apart.
  context 'with a subgroup' do
    let_it_be(:parent) { create(:group, name: 'Acme Corp') } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check
    let_it_be(:group) { create(:group, name: 'Platform Engineering', parent: parent) } # rubocop:disable RSpec/FactoryBot/AvoidCreate -- real membership needed for the can?(:destroy_group_member) check

    let(:full_name) { 'Acme Corp / Platform Engineering' }

    before_all do
      group.add_developer(user)
    end

    it 'labels the row with the group name alone' do
      render_notification([group])

      expect(rendered).to have_css("[data-testid='two-factor-groups-notification'] > li",
        text: 'Platform Engineering', visible: :all)
      expect(rendered).not_to have_text(full_name)
    end

    it 'names the ancestors in the confirmation, where the group must be unambiguous' do
      render_notification([group])

      expect(rendered).to have_css(
        "[data-testid='two-factor-leave-group-button']" \
          "[data-confirm='#{format(s_('GroupsTree|Are you sure you want to leave \"%{fullName}\"?'),
            fullName: full_name)}']",
        visible: :all
      )
    end
  end
end

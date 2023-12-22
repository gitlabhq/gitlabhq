# frozen_string_literal: true

RSpec.shared_examples 'inviting groups search results' do
  context 'with instance admin considerations' do
    let_it_be(:group_to_invite) { create(:group) }

    context 'when user is an admin' do
      let_it_be(:admin) { create(:admin) }

      before do
        sign_in(admin)
        enable_admin_mode!(admin)
      end

      it 'shows groups where the admin has no direct membership' do
        visit members_page_path

        click_on 'Invite a group'
        click_on 'Select a group'
        wait_for_requests

        page.within(group_dropdown_selector) do
          expect_to_have_group(group_to_invite)
          expect_not_to_have_group(group)
        end
      end

      it 'shows groups where the admin has at least guest level membership' do
        group_to_invite.add_guest(admin)

        visit members_page_path

        click_on 'Invite a group'
        click_on 'Select a group'
        wait_for_requests

        page.within(group_dropdown_selector) do
          expect_to_have_group(group_to_invite)
          expect_not_to_have_group(group)
        end
      end
    end

    context 'when user is not an admin' do
      before do
        group.add_owner(user)
        sign_in(user)
      end

      it 'does not show groups where the user has no direct membership' do
        visit members_page_path

        click_on 'Invite a group'
        click_on 'Select a group'
        wait_for_requests

        page.within(group_dropdown_selector) do
          expect_not_to_have_group(group_to_invite)
          expect_not_to_have_group(group)
        end
      end

      it 'shows groups where the user has at least guest level membership' do
        group_to_invite.add_guest(user)

        visit members_page_path

        click_on 'Invite a group'
        click_on 'Select a group'
        wait_for_requests

        page.within(group_dropdown_selector) do
          expect_to_have_group(group_to_invite)
          expect_not_to_have_group(group)
        end
      end
    end
  end

  context 'when user is not an admin and there are hierarchy considerations' do
    let_it_be(:group_outside_hierarchy) { create(:group) }

    before_all do
      group.add_owner(user)
      group_within_hierarchy.add_owner(user)
      group_outside_hierarchy.add_owner(user)
    end

    before do
      sign_in(user)
    end

    it 'does not show self or ancestors', :aggregate_failures do
      group_sibling = create(:group, parent: group)
      group_sibling.add_owner(user)

      visit members_page_path_within_hierarchy

      click_on 'Invite a group'
      click_on 'Select a group'
      wait_for_requests

      page.within(group_dropdown_selector) do
        expect_to_have_group(group_outside_hierarchy)
        expect_to_have_group(group_sibling)
        expect_not_to_have_group(group)
        expect_not_to_have_group(group_within_hierarchy)
      end
    end

    context 'when sharing with groups outside the hierarchy is enabled' do
      it 'shows groups within and outside the hierarchy in search results' do
        visit members_page_path

        click_on 'Invite a group'
        click_on 'Select a group'
        wait_for_requests

        page.within(group_dropdown_selector) do
          expect_to_have_group(group_within_hierarchy)
          expect_to_have_group(group_outside_hierarchy)
        end
      end
    end

    context 'when sharing with groups outside the hierarchy is disabled' do
      before do
        group.update!(prevent_sharing_groups_outside_hierarchy: true)
      end

      it 'shows only groups within the hierarchy in search results' do
        visit members_page_path

        click_on 'Invite a group'
        click_on 'Select a group'

        page.within(group_dropdown_selector) do
          expect_to_have_group(group_within_hierarchy)
          expect_not_to_have_group(group_outside_hierarchy)
        end
      end
    end
  end
end

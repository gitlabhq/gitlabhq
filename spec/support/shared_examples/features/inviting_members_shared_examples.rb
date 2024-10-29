# frozen_string_literal: true

RSpec.shared_examples 'inviting members' do |snowplow_invite_label|
  before_all do
    group.add_owner(user1)
  end

  it 'adds user as member', :js, :snowplow, :aggregate_failures do
    visit members_page_path

    invite_member(user2.name, role: 'Reporter')

    page.within find_member_row(user2) do
      expect(page).to have_button('Reporter')
    end

    expect_snowplow_event(
      category: 'Members::InviteService',
      action: 'create_member',
      label: snowplow_invite_label,
      property: 'existing_user',
      user: user1
    )
  end

  it 'displays the user\'s avatar in the member input token', :js do
    visit members_page_path

    input_invites(user2.name)

    expect(page).to have_selector(member_token_avatar_selector)
  end

  it 'does not display an avatar in the member input token for an email address', :js do
    visit members_page_path

    input_invites('test@example.com')

    expect(page).not_to have_selector(member_token_avatar_selector)
  end

  it 'invites user by email', :js, :snowplow, :aggregate_failures do
    visit members_page_path

    invite_member('test@example.com', role: 'Reporter')

    click_link 'Pending invitations'

    page.within find_invited_member_row('test@example.com') do
      expect(page).to have_button('Reporter')
    end

    expect_snowplow_event(
      category: 'Members::InviteService',
      action: 'create_member',
      label: snowplow_invite_label,
      property: 'net_new_user',
      user: user1
    )
  end

  it 'invites user by username and invites user by email', :js, :aggregate_failures do
    visit members_page_path

    invite_member([user2.name, 'test@example.com'], role: 'Reporter')

    page.within find_member_row(user2) do
      expect(page).to have_button('Reporter')
    end

    click_link 'Pending invitations'

    page.within find_invited_member_row('test@example.com') do
      expect(page).to have_button('Reporter')
    end
  end

  context 'when member is already a member by username' do
    it 'updates the member for that user', :js do
      entity.add_developer(user2)

      visit members_page_path

      invite_member(user2.name, role: 'Reporter')

      expect(page).not_to have_selector(invite_modal_selector)

      page.refresh

      page.within find_invited_member_row(user2.name) do
        expect(page).to have_button('Reporter')
      end
    end
  end

  context 'when member is already a member by email' do
    it 'updates the member for that email', :js do
      email = 'test@example.com'
      entity.add_developer(email)

      visit members_page_path

      invite_member(email, role: 'Reporter')

      expect(page).not_to have_selector(invite_modal_selector)

      page.refresh

      click_link 'Pending invitations'

      page.within find_invited_member_row(email) do
        expect(page).to have_button('Reporter')
      end
    end
  end

  context 'when inviting a parent group member to the sub-entity' do
    before_all do
      group.add_owner(user1)
      group.add_developer(user2)
    end

    context 'when role is higher than parent group membership' do
      let(:role) { 'Maintainer' }

      it 'adds the user as a member on sub-entity with higher access level', :js do
        visit subentity_members_page_path

        invite_member(user2.name, role: role)

        expect(page).not_to have_selector(invite_modal_selector)

        page.refresh

        page.within find_invited_member_row(user2.name) do
          expect(page).to have_button(role)
        end
      end
    end

    context 'when role is lower than parent group membership' do
      let(:role) { 'Reporter' }

      it 'fails with an error', :js do
        visit subentity_members_page_path

        invite_member(user2.name, role: role)

        invite_modal = page.find(invite_modal_selector)
        expect(invite_modal).to have_content "#{user2.name}: Access level should be greater than or equal to " \
                                             "Developer inherited membership from group #{group.name}"

        page.refresh

        page.within find_invited_member_row(user2.name) do
          expect(page).to have_content('Developer')
          expect(page).not_to have_button('Developer')
        end
      end

      context 'when a user already exists, and private email is used' do
        it 'fails with an error', :js do
          visit subentity_members_page_path

          invite_member(user2.email, role: role)

          invite_modal = page.find(invite_modal_selector)
          expect(invite_modal).to have_content "#{user2.email}: Access level should be greater than or equal to " \
                                               "Developer inherited membership from group #{group.name}"

          page.refresh

          page.within find_invited_member_row(user2.name) do
            expect(page).to have_content('Developer')
            expect(page).not_to have_button('Developer')
          end
        end

        it 'does not allow inviting of an email that has spaces', :js do
          visit subentity_members_page_path

          click_on _('Invite members')
          wait_for_requests

          page.within invite_modal_selector do
            choose_options(role, nil)
            find(member_dropdown_selector).set("#{user2.email} ")
            wait_for_requests

            expect(page).to have_content('No matches found')
            expect(page).not_to have_button("#{user2.email} ")
          end
        end
      end

      context 'when there are multiple users invited with errors' do
        let_it_be(:user3) { create(:user) }

        before do
          group.add_maintainer(user3)
        end

        it 'shows the partial user error and success and then removes them from the form', :js do
          user4 = create(:user)
          user5 = create(:user)
          user6 = create(:user)
          user7 = create(:user)

          group.add_maintainer(user6)
          group.add_maintainer(user7)

          visit subentity_members_page_path

          invite_member([user2.name, user3.name, user4.name, user6.name, user7.name], role: role)

          # we have more than 2 errors, so one will be hidden
          invite_modal = page.find(invite_modal_selector)
          expect(invite_modal).to have_text("The following 4 members couldn't be invited")
          expect(invite_modal).to have_selector(limited_invite_error_selector, count: 2, visible: :visible)
          expect(invite_modal).to have_selector(expanded_invite_error_selector, count: 2, visible: :hidden)
          # unpredictability of return order means we can't rely on message showing in any order here
          # so we will not expect on the message
          expect_to_have_invalid_invite_indicator(invite_modal, user2, message: false)
          expect_to_have_invalid_invite_indicator(invite_modal, user3, message: false)
          expect_to_have_invalid_invite_indicator(invite_modal, user6, message: false)
          expect_to_have_invalid_invite_indicator(invite_modal, user7, message: false)
          expect_to_have_successful_invite_indicator(invite_modal, user4)
          expect(invite_modal).to have_button('Show more (2)')

          # now we want to test the show more errors count logic
          remove_token(user7.id)

          # count decreases from 4 to 3 and 2 to 1
          expect(invite_modal).to have_text("The following 3 members couldn't be invited")
          expect(invite_modal).to have_button('Show more (1)')

          # we want to show this error now for user6
          invite_modal.find(more_invite_errors_button_selector).click

          # now we should see the error for all users and our collapse button text
          expect(invite_modal).to have_selector(limited_invite_error_selector, count: 2, visible: :visible)
          expect(invite_modal).to have_selector(expanded_invite_error_selector, count: 1, visible: :visible)
          expect_to_have_invalid_invite_indicator(invite_modal, user2, message: true)
          expect_to_have_invalid_invite_indicator(invite_modal, user3, message: true)
          expect_to_have_invalid_invite_indicator(invite_modal, user6, message: true)
          expect(invite_modal).to have_button('Show less')

          # adds new token, but doesn't submit
          select_members(user5.name)

          expect_to_have_normal_invite_indicator(invite_modal, user5)

          remove_token(user2.id)

          expect(invite_modal).to have_text("The following 2 members couldn't be invited")
          expect(invite_modal).not_to have_selector(more_invite_errors_button_selector)
          expect_to_have_invite_removed(invite_modal, user2)
          expect_to_have_invalid_invite_indicator(invite_modal, user3)
          expect_to_have_invalid_invite_indicator(invite_modal, user6)
          expect_to_have_successful_invite_indicator(invite_modal, user4)
          expect_to_have_normal_invite_indicator(invite_modal, user5)

          remove_token(user6.id)

          expect(invite_modal).to have_text("The following member couldn't be invited")
          expect_to_have_invite_removed(invite_modal, user6)
          expect_to_have_invalid_invite_indicator(invite_modal, user3)
          expect_to_have_successful_invite_indicator(invite_modal, user4)
          expect_to_have_normal_invite_indicator(invite_modal, user5)

          remove_token(user3.id)

          expect(invite_modal).not_to have_text("The following member couldn't be invited")
          expect(invite_modal).not_to have_text("Review the invite errors and try again")
          expect_to_have_invite_removed(invite_modal, user3)
          expect_to_have_successful_invite_indicator(invite_modal, user4)
          expect_to_have_normal_invite_indicator(invite_modal, user5)

          submit_invites

          expect(page).not_to have_selector(invite_modal_selector)

          page.refresh

          page.within find_invited_member_row(user2.name) do
            expect(page).to have_content('Developer')
            expect(page).not_to have_button('Developer')
          end

          page.within find_invited_member_row(user3.name) do
            expect(page).to have_content('Maintainer')
            expect(page).not_to have_button('Maintainer')
          end

          page.within find_invited_member_row(user4.name) do
            expect(page).to have_button(role)
          end
        end

        it 'only shows the error for an invalid formatted email and does not display other member errors', :js do
          visit subentity_members_page_path

          invite_member([user2.name, user3.name, 'bad@email'], role: role)

          invite_modal = page.find(invite_modal_selector)
          expect(invite_modal).to have_text('email contains an invalid email address')
          expect(invite_modal).not_to have_text("The following 2 members couldn't be invited")
          expect(invite_modal).not_to have_text("Review the invite errors and try again")
          expect(invite_modal).not_to have_text("#{user2.name}: Access level should be greater than or equal to")
          expect(invite_modal).not_to have_text("#{user3.name}: Access level should be greater than or equal to")
        end
      end
    end
  end
end

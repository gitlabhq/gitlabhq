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

    click_link 'Invited'

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

    click_link 'Invited'

    page.within find_invited_member_row('test@example.com') do
      expect(page).to have_button('Reporter')
    end
  end

  context 'when member is already a member by username' do
    it 'updates the member for that user', :js do
      visit members_page_path

      invite_member(user2.name, role: 'Developer')

      invite_member(user2.name, role: 'Reporter', refresh: false)

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

      visit members_page_path

      invite_member(email, role: 'Developer')

      invite_member(email, role: 'Reporter', refresh: false)

      expect(page).not_to have_selector(invite_modal_selector)

      page.refresh

      click_link 'Invited'

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

        invite_member(user2.name, role: role, refresh: false)

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

        invite_member(user2.name, role: role, refresh: false)

        expect(page).to have_selector(invite_modal_selector)
        expect(page).to have_content "#{user2.name}: Access level should be greater than or equal to Developer " \
                                     "inherited membership from group #{group.name}"

        page.refresh

        page.within find_invited_member_row(user2.name) do
          expect(page).to have_content('Developer')
          expect(page).not_to have_button('Developer')
        end
      end

      context 'when there are multiple users invited with errors' do
        let_it_be(:user3) { create(:user) }

        before do
          group.add_maintainer(user3)
        end

        it 'shows the user errors and then removes them from the form', :js do
          visit subentity_members_page_path

          invite_member([user2.name, user3.name], role: role, refresh: false)

          expect(page).to have_selector(invite_modal_selector)
          expect(page).to have_selector(member_token_error_selector(user2.id))
          expect(page).to have_selector(member_token_error_selector(user3.id))
          expect(page).to have_text("The following 2 members couldn't be invited")
          expect(page).to have_text("#{user2.name}: Access level should be greater than or equal to")
          expect(page).to have_text("#{user3.name}: Access level should be greater than or equal to")

          remove_token(user2.id)

          expect(page).not_to have_selector(member_token_error_selector(user2.id))
          expect(page).to have_selector(member_token_error_selector(user3.id))
          expect(page).to have_text("The following member couldn't be invited")
          expect(page).not_to have_text("#{user2.name}: Access level should be greater than or equal to")

          remove_token(user3.id)

          expect(page).not_to have_selector(member_token_error_selector(user3.id))
          expect(page).not_to have_text("The following member couldn't be invited")
          expect(page).not_to have_text("Review the invite errors and try again")
          expect(page).not_to have_text("#{user3.name}: Access level should be greater than or equal to")

          page.refresh

          page.within find_invited_member_row(user2.name) do
            expect(page).to have_content('Developer')
            expect(page).not_to have_button('Developer')
          end

          page.within find_invited_member_row(user3.name) do
            expect(page).to have_content('Maintainer')
            expect(page).not_to have_button('Maintainer')
          end
        end

        it 'only shows the error for an invalid formatted email and does not display other member errors', :js do
          visit subentity_members_page_path

          invite_member([user2.name, user3.name, 'bad@email'], role: role, refresh: false)

          expect(page).to have_selector(invite_modal_selector)
          expect(page).to have_text('email contains an invalid email address')
          expect(page).not_to have_text("The following 2 members couldn't be invited")
          expect(page).not_to have_text("Review the invite errors and try again")
          expect(page).not_to have_text("#{user2.name}: Access level should be greater than or equal to")
          expect(page).not_to have_text("#{user3.name}: Access level should be greater than or equal to")
        end
      end
    end
  end
end

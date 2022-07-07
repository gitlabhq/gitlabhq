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
      visit members_page_path

      invite_member('test@example.com', role: 'Developer')

      invite_member('test@example.com', role: 'Reporter', refresh: false)

      expect(page).not_to have_selector(invite_modal_selector)

      page.refresh

      click_link 'Invited'

      page.within find_invited_member_row('test@example.com') do
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
        expect(page).to have_content "Access level should be greater than or equal to Developer inherited membership " \
                                     "from group #{group.name}"

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

        it 'only shows the first user error', :js do
          visit subentity_members_page_path

          invite_member([user2.name, user3.name], role: role, refresh: false)

          expect(page).to have_selector(invite_modal_selector)
          expect(page).to have_text("Access level should be greater than or equal to", count: 1)

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
      end
    end
  end
end

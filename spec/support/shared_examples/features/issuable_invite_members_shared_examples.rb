# frozen_string_literal: true

RSpec.shared_examples 'issuable invite members' do
  include Features::InviteMembersModalHelpers

  context 'when a privileged user can invite' do
    it 'shows a link for inviting members and launches invite modal' do
      project.add_maintainer(user)
      visit issuable_path

      open_assignees_dropdown

      page.within '.dropdown-menu-user' do
        expect(page).to have_link('Invite members')

        click_link 'Invite members'
      end

      page.within invite_modal_selector do
        expect(page).to have_content("You're inviting members to the #{project.name} project")
      end
    end
  end

  context 'when user cannot invite members in assignee dropdown' do
    it 'shows author in assignee dropdown and no invite link' do
      project.add_developer(user)
      visit issuable_path

      open_assignees_dropdown

      page.within '.dropdown-menu-user' do
        expect(page).not_to have_link('Invite members')
      end
    end
  end
end

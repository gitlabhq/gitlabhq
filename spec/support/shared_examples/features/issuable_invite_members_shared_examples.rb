# frozen_string_literal: true

RSpec.shared_examples 'issuable invite members' do
  context 'when a privileged user can invite' do
    before do
      project.add_maintainer(user)
    end

    it 'shows a link for inviting members and launches invite modal' do
      visit issuable_path

      find('.block.assignee .edit-link').click

      wait_for_requests

      page.within '.dropdown-menu-user' do
        expect(page).to have_link('Invite Members')
        expect(page).to have_selector('[data-track-event="click_invite_members"]')
        expect(page).to have_selector('[data-track-label="edit_assignee"]')
      end

      click_link 'Invite Members'

      expect(page).to have_content("You're inviting members to the")
    end
  end

  context 'when user cannot invite members in assignee dropdown' do
    before do
      project.add_developer(user)
    end

    it 'shows author in assignee dropdown and no invite link' do
      visit issuable_path

      find('.block.assignee .edit-link').click

      wait_for_requests

      page.within '.dropdown-menu-user' do
        expect(page).not_to have_link('Invite Members')
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.shared_examples 'confidential notes on issuables' do
  include Features::NotesHelpers

  context 'when user does not have permissions' do
    it 'does not show confidential note checkbox' do
      issuable_parent.add_guest(user)
      sign_in(user)
      visit(issuable_path)

      page.within('.new-note') do
        expect(page).not_to have_selector('[data-testid="internal-note-checkbox"]')
      end
    end
  end

  context 'when user has permissions' do
    it 'creates confidential note' do
      issuable_parent.add_reporter(user)
      sign_in(user)
      visit(issuable_path)

      find('[data-testid="internal-note-checkbox"]').click
      add_note('Confidential note')

      page.within('.note-header') do
        expect(page).to have_selector('[data-testid="internal-note-indicator"]')
      end
    end
  end
end

# frozen_string_literal: true

require "spec_helper"

RSpec.shared_examples 'confidential notes on issuables' do
  include Features::NotesHelpers

  context 'when user does not have permissions' do
    it 'does not show confidential note checkbox' do
      issuable_parent.add_guest(user)
      sign_in(user)
      visit(issuable_path)

      expect(page).not_to have_unchecked_field('Make this an internal note')
    end
  end

  context 'when user has permissions' do
    it 'creates confidential note' do
      issuable_parent.add_reporter(user)
      sign_in(user)
      visit(issuable_path)

      fill_in 'Add a reply', with: 'Confidential note'
      check 'Make this an internal note'
      click_button 'Comment'

      within_testid('note-wrapper') do
        expect(page).to have_css('.gl-badge', text: 'Internal note')
        expect(page).to have_text('Confidential note')
      end
    end
  end
end

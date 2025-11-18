# frozen_string_literal: true

RSpec.shared_examples 'reportable note' do |type|
  include MobileHelpers
  include NotesHelper

  let(:comment) { find("##{ActionView::RecordIdentifier.dom_id(note)}") }

  it 'has an edit button' do
    within(comment) do
      expect(page).to have_button('Edit comment')
    end
  end

  it 'has delete link' do
    within(comment) do
      click_button 'More actions'

      if type == 'issue' || type == 'merge_request'
        expect(page).to have_button('Delete comment')
      else
        expect(page).to have_link('Delete comment', href: note_url(note, project))
      end
    end
  end

  it 'report button links to a report page' do
    within(comment) do
      click_button 'More actions'
      click_button('Report abuse')
    end
    choose "They're posting spam."
    click_button "Next"

    expect(find('#user_name')['value']).to match(note.author.username)
    expect(find('#abuse_report_reported_from_url')['value']).to match(noteable_note_url(note))
    expect(find('#abuse_report_category', visible: false)['value']).to match('spam')
  end
end

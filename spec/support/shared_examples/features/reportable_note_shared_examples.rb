# frozen_string_literal: true

RSpec.shared_examples 'reportable note' do |type|
  include MobileHelpers
  include NotesHelper

  let(:comment) { find("##{ActionView::RecordIdentifier.dom_id(note)}") }
  let(:more_actions_selector) { '.more-actions.dropdown' }

  it 'has an edit button' do
    expect(comment).to have_selector('.js-note-edit')
  end

  it 'has a `More actions` dropdown' do
    expect(comment).to have_selector(more_actions_selector)
  end

  it 'dropdown has Report and Delete links' do
    dropdown = comment.find(more_actions_selector)
    open_dropdown(dropdown)

    expect(dropdown).to have_button('Report abuse')

    if type == 'issue' || type == 'merge_request'
      expect(dropdown).to have_button('Delete comment')
    else
      expect(dropdown).to have_link('Delete comment', href: note_url(note, project))
    end
  end

  it 'report button links to a report page' do
    dropdown = comment.find(more_actions_selector)
    open_dropdown(dropdown)

    dropdown.click_button('Report abuse')

    choose "They're posting spam."
    click_button "Next"

    expect(find('#user_name')['value']).to match(note.author.username)
    expect(find('#abuse_report_reported_from_url')['value']).to match(noteable_note_url(note))
    expect(find('#abuse_report_category', visible: false)['value']).to match('spam')
  end

  def open_dropdown(dropdown)
    # make window wide enough that tooltip doesn't trigger horizontal scrollbar
    restore_window_size

    dropdown.find('.more-actions-toggle').click
    dropdown.find('.more-actions li', match: :first)
  end
end

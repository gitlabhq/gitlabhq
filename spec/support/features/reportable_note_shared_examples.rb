require 'spec_helper'

shared_examples 'reportable note' do |is_a_personal_snippet|
  include NotesHelper

  let(:comment) { find("##{ActionView::RecordIdentifier.dom_id(note)}") }
  let(:more_actions_selector) { '.more-actions.dropdown' }
  let(:abuse_report_path) { new_abuse_report_path(user_id: note.author.id, ref_url: noteable_note_url(note)) }

  it 'has a `More actions` dropdown' do
    expect(comment).to have_selector(more_actions_selector)
  end

  if is_a_personal_snippet
    it 'dropdown has Report link on other users comment' do
      dropdown = comment.find(more_actions_selector)
      open_dropdown(dropdown)

      expect(dropdown).to have_link('Report as abuse', href: abuse_report_path)
    end

    it 'dropdown has Edit and Delete links on the owners comment' do
      find('#notes-list .note', match: :first)
      other_comment = all('#notes-list .note').last

      dropdown = other_comment.find(more_actions_selector)
      open_dropdown(dropdown)

      expect(dropdown).to have_button('Edit comment')
      expect(dropdown).to have_link('Delete comment', href: note_url(owners_note, project))
    end
  else
    it 'dropdown has Edit, Report and Delete links' do
      dropdown = comment.find(more_actions_selector)
      open_dropdown(dropdown)

      expect(dropdown).to have_button('Edit comment')
      expect(dropdown).to have_link('Report as abuse', href: abuse_report_path)
      expect(dropdown).to have_link('Delete comment', href: note_url(note, project))
    end
  end

  it 'Report button links to a report page' do
    dropdown = comment.find(more_actions_selector)
    open_dropdown(dropdown)

    dropdown.click_link('Report as abuse')

    expect(find('#user_name')['value']).to match(note.author.username)
    expect(find('#abuse_report_message')['value']).to match(noteable_note_url(note))
  end

  def open_dropdown(dropdown)
    dropdown.click
    dropdown.find('.dropdown-menu li', match: :first)
  end
end

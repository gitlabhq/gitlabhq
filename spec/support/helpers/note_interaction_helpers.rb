# frozen_string_literal: true

module NoteInteractionHelpers
  include MergeRequestDiffHelpers

  def open_more_actions_dropdown(note)
    note_element = find_by_scrolling("#note_#{note.id}")

    note_element.find('.more-actions-toggle').click
    note_element.find('.more-actions li', match: :first)
  end
end

module NoteInteractionHelpers
  def open_more_actions_dropdown(note)
    note_element = find("#note_#{note.id}")

    note_element.find('.more-actions-toggle').click
    note_element.find('.more-actions .dropdown-menu li', match: :first)
  end
end

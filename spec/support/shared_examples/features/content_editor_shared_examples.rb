# frozen_string_literal: true

RSpec.shared_examples 'edits content using the content editor' do
  it 'formats text as bold using bubble menu' do
    content_editor_testid = '[data-testid="content-editor"] [contenteditable]'

    expect(page).to have_css(content_editor_testid)

    find(content_editor_testid).send_keys 'Typing text in the content editor'
    find(content_editor_testid).send_keys [:shift, :left]

    expect(page).to have_css('[data-testid="formatting-bubble-menu"]')
  end
end

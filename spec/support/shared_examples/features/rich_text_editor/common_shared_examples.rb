# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - common' do
  include RichTextEditorHelpers

  it 'saves page content in local storage if the user navigates away' do
    switch_to_content_editor

    expect(page).to have_css(content_editor_testid)

    type_in_content_editor ' Typing text in the content editor'

    wait_until_hidden_field_is_updated(/Typing text in the content editor/)

    begin
      refresh
    rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError
    end

    expect(page).to have_text('Typing text in the content editor')
  end

  it 'autofocuses the rich text editor when switching to rich text' do
    switch_to_content_editor

    expect(page).to have_css("#{content_editor_testid}:focus")
  end

  it 'autofocuses the plain text editor when switching back to markdown' do
    switch_to_content_editor
    switch_to_markdown_editor

    expect(page).to have_css("textarea:focus")
  end

  describe 'rendering with initial content' do
    it 'serializes basic markdown content properly' do
      find('textarea').set('')

      switch_to_content_editor

      expect(page).to have_css(content_editor_testid)

      type_in_content_editor "hello world"
      type_in_content_editor :enter
      type_in_content_editor "* list item 1"
      type_in_content_editor :enter
      type_in_content_editor "list item 2"

      wait_until_hidden_field_is_updated(/list item/)

      switch_to_markdown_editor

      expect(page.find('textarea').value).to include('hello world

* list item 1
* list item 2')
    end

    it 'renders correctly with table as initial content' do
      textarea = find 'textarea'
      textarea.send_keys "\n\n"
      textarea.send_keys "| First Header | Second Header |\n"
      textarea.send_keys "|--------------|---------------|\n"
      textarea.send_keys "| Content from cell 1 | Content from cell 2 |\n\n"
      textarea.send_keys "Content below table"

      switch_to_content_editor

      expect(page).not_to have_text('An error occurred')
    end

    it 'renders correctly with checklist as initial content' do
      textarea = find 'textarea'
      textarea.send_keys "\n\n"
      textarea.send_keys "- [ ] checklist\n"
      # remove auto inserted `- [ ] `
      textarea.send_keys [:backspace] * 6
      textarea.send_keys "  - [ ] nested checklist\n"
      textarea.send_keys "nested checklist 2"

      switch_to_content_editor

      # check the checkbox titled `nested checklist`
      within content_editor_testid do
        all("[type=checkbox]")[1].click
      end
      wait_until_hidden_field_is_updated(/\[x\]/)

      switch_to_markdown_editor

      expect(page.find('textarea').value).to include('- [ ] checklist
  - [x] nested checklist
  - [ ] nested checklist 2')
    end
  end

  describe 'automatically resolving references' do
    before do
      create(:user, name: 'abc123', username: 'abc123')

      switch_to_content_editor
      type_in_content_editor :enter
    end

    it 'resolves a user reference when typing a username' do
      type_in_content_editor '@abc123 some text'

      expect(page).to have_link('@abc123', href: "/abc123")
    end

    it 'does not resolve a user reference for a user that does not exist' do
      type_in_content_editor '@nonexistentuser some text'

      expect(page).not_to have_link('@nonexistentuser')
    end

    it 'does not resolve a user reference when typing a username in an inline code block' do
      type_in_content_editor "`@abc123` some text"

      expect(page).not_to have_link('@abc123')
    end
  end

  describe 'block content is added to a table' do
    it 'converts a markdown table to HTML and shows a warning for it' do
      click_on 'Insert table'
      click_on 'Insert a 2×2 table'

      switch_to_content_editor
      type_in_content_editor '* list item'

      expect(page).to have_text(
        "Tables containing block elements (like multiple paragraphs, lists or blockquotes) are not \
supported in Markdown and will be converted to HTML."
      )

      switch_to_markdown_editor
      expect(page.find('textarea').value).to include '<table>
<tr>
<th>header</th>
<th>header</th>
</tr>
<tr>
<td></td>
<td></td>
</tr>
<tr>
<td></td>
<td>

* list item
</td>
</tr>
</table>'
    end
  end
end

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
  end

  describe 'block content is added to a table' do
    it 'converts a markdown table to HTML and shows a warning for it' do
      click_on 'Add a table'

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
<td>

</td>
<td>

</td>
</tr>
<tr>
<td>

</td>
<td>

* list item
</td>
</tr>
</table>'
    end
  end
end

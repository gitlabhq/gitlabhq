# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - common' do
  include RichTextEditorHelpers

  let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
  let(:modifier_key) { is_mac ? :command : :control }

  it 'keeps the document when undo is pressed after switching back to rich text', feature_category: :markdown do
    switch_to_content_editor

    type_in_content_editor 'Undo keeps this text'
    wait_until_hidden_field_is_updated(/Undo keeps this text/)

    # Switching away and back remounts the editor, so the reload is its only history step.
    switch_to_markdown_editor
    switch_to_content_editor

    within(content_editor_testid) do
      expect(page).to have_text('Undo keeps this text')
    end

    type_in_content_editor [modifier_key, 'z']

    within(content_editor_testid) do
      expect(page).to have_text('Undo keeps this text')
    end

    type_in_content_editor ' plus more'
    wait_until_hidden_field_is_updated(/Undo keeps this text plus more/)

    type_in_content_editor [modifier_key, 'z']

    within(content_editor_testid) do
      expect(page).to have_text('Undo keeps this text')
      expect(page).not_to have_text('plus more')
    end
  end

  it 'saves page content in local storage if the user navigates away', feature_category: :markdown do
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

  it 'autofocuses the rich text editor when switching to rich text', feature_category: :markdown do
    switch_to_content_editor

    expect(page).to have_css("#{content_editor_testid}:focus")
  end

  it 'autofocuses the plain text editor when switching back to markdown', feature_category: :markdown do
    switch_to_content_editor
    switch_to_markdown_editor

    expect(page).to have_css("textarea:focus")
  end

  describe 'rendering with initial content', feature_category: :markdown do
    it 'serializes basic markdown content properly' do
      find('textarea').set('')

      switch_to_content_editor

      expect(page).to have_css(content_editor_testid)

      type_in_content_editor "hello world"
      type_in_content_editor :enter
      type_in_content_editor "* list item 1"
      type_in_content_editor :enter
      type_in_content_editor "list item 2"

      wait_until_hidden_field_is_updated(/list item 2/)

      switch_to_markdown_editor

      expect(page.find('textarea').value).to include('hello world

* list item 1
* list item 2')
    end

    describe 'with a placeholder' do
      let(:placeholder_selector) { '[data-testid="content-editor-placeholder"]' }

      before do
        find('textarea').set('Server: %{gitlab_server}')
        switch_to_content_editor
      end

      it 'displays the value with the placeholder syntax in a tooltip on hover' do
        page.within content_editor_testid do
          find(placeholder_selector, text: Gitlab.config.gitlab.host).hover
        end

        expect(page).to have_css('[role="tooltip"]', text: '%{gitlab_server}')
      end

      it 'shows and announces the placeholder syntax when reselected with the keyboard' do
        announcement_selector = '[data-testid="content-editor-placeholder-announcement"]'
        announcement = format(s_('ContentEditor|%{value}, placeholder %{placeholder}'),
          value: Gitlab.config.gitlab.host, placeholder: '%{gitlab_server}')

        page.within content_editor_testid do
          find(placeholder_selector).click

          expect(page).to have_css(announcement_selector, visible: :all, exact_text: announcement)
        end

        find_button('Switch to plain text editing').hover
        type_in_content_editor :right

        page.within content_editor_testid do
          expect(page).to have_css(announcement_selector, visible: :all, exact_text: '')
        end

        expect(page).to have_no_css('[role="tooltip"]', text: '%{gitlab_server}')

        type_in_content_editor :left

        page.within content_editor_testid do
          expect(page).to have_css(announcement_selector, visible: :all, exact_text: announcement)
        end

        expect(page).to have_css('[role="tooltip"]', text: '%{gitlab_server}')
      end

      it 'preserves the placeholder syntax when switching back to markdown' do
        page.within content_editor_testid do
          expect(page).to have_css(placeholder_selector)
        end

        type_in_content_editor :end
        type_in_content_editor ' hello world'
        wait_until_hidden_field_is_updated(/hello world/)

        switch_to_markdown_editor

        expect(page).to have_field(type: 'textarea', with: 'Server: %{gitlab_server} hello world')
      end
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

  describe 'automatically resolving references', feature_category: :markdown do
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

  describe 'block content is added to a table', feature_category: :markdown do
    it 'converts a markdown table to HTML and shows a warning for it' do
      click_on 'Insert table'
      click_on 'Insert a 2×2 table'

      switch_to_content_editor

      within(content_editor_testid) do
        expect(page).to have_content('header')
      end

      type_in_content_editor '* list item'

      expect(page).to have_text(
        "Tables containing block elements (like multiple paragraphs, lists or blockquotes, or task \
lists with text or multiple items) are not supported in Markdown and will be converted to HTML."
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

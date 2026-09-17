# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - code blocks' do
  include RichTextEditorHelpers

  describe 'code block', feature_category: :markdown do
    before do
      visit(profile_preferences_path)

      find('[data-testid="syntax-highlighting-light-color-scheme"]').choose('Dark')

      wait_for_requests

      page.go_back
      refresh
      switch_to_content_editor
    end

    it 'applies theme classes to code blocks' do
      expect(page).not_to have_css('.content-editor-code-block.code.highlight.code-syntax-highlight-theme')

      type_in_content_editor [:enter, :enter]
      type_in_content_editor '```js ' # trigger input rule
      type_in_content_editor 'var a = 0'

      expect(page).to have_css('.content-editor-code-block.code.highlight.code-syntax-highlight-theme')
    end
  end

  describe 'code block bubble menu', feature_category: :markdown do
    before do
      switch_to_content_editor
    end

    it 'shows a code block bubble menu for a code block' do
      type_in_content_editor [:enter, :enter]

      type_in_content_editor '```js ' # trigger input rule
      type_in_content_editor 'var a = 0'
      type_in_content_editor [:shift, :left]

      expect(page).to have_css('[data-testid="code-block-bubble-menu"]')
    end

    it 'sets code block type to "javascript" for `js`' do
      type_in_content_editor [:enter, :enter]

      type_in_content_editor '```js '
      type_in_content_editor 'var a = 0'

      expect(find('[data-testid="code-block-bubble-menu"]')).to have_text('Javascript')
    end

    it 'sets code block type to "Custom (nomnoml)" for `nomnoml`' do
      type_in_content_editor [:enter, :enter]

      type_in_content_editor '```nomnoml '
      type_in_content_editor 'test'

      expect(find('[data-testid="code-block-bubble-menu"]')).to have_text('Custom (nomnoml)')
    end
  end

  describe 'switching between editors', feature_category: :markdown do
    it 'keeps lines starting with a slash inside a code block intact' do
      markdown = "```\nvar test1 10\n// testing comment\n/usr/bin/env bash\ntest 1\n```\n\nNotes"

      find('textarea').set(markdown)
      switch_to_content_editor

      expect(page).to have_css("#{content_editor_testid} pre", text: 'testing comment')

      type_in_content_editor ' edited'
      wait_until_hidden_field_is_updated(/Notes edited/)

      switch_to_markdown_editor

      expect(find('textarea').value).to eq(markdown.sub('Notes', 'Notes edited'))
    end
  end
end

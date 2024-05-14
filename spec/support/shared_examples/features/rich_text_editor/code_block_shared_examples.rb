# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - code blocks' do
  include RichTextEditorHelpers

  describe 'code block' do
    before do
      visit(profile_preferences_path)

      find('.syntax-theme').choose('Dark')

      wait_for_requests

      page.go_back
      refresh
      switch_to_content_editor
    end

    it 'applies theme classes to code blocks' do
      expect(page).not_to have_css('.content-editor-code-block.code.highlight.dark')

      type_in_content_editor [:enter, :enter]
      type_in_content_editor '```js ' # trigger input rule
      type_in_content_editor 'var a = 0'

      expect(page).to have_css('.content-editor-code-block.code.highlight.dark')
    end
  end

  describe 'code block bubble menu' do
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
end

# frozen_string_literal: true

RSpec.shared_examples 'edits content using the content editor' do
  content_editor_testid = '[data-testid="content-editor"] [contenteditable].ProseMirror'

  describe 'formatting bubble menu' do
    it 'shows a formatting bubble menu for a regular paragraph' do
      expect(page).to have_css(content_editor_testid)

      find(content_editor_testid).send_keys 'Typing text in the content editor'
      find(content_editor_testid).send_keys [:shift, :left]

      expect(page).to have_css('[data-testid="formatting-bubble-menu"]')
    end

    it 'does not show a formatting bubble menu for code' do
      find(content_editor_testid).send_keys 'This is a `code`'
      find(content_editor_testid).send_keys [:shift, :left]

      expect(page).not_to have_css('[data-testid="formatting-bubble-menu"]')
    end
  end

  describe 'code block bubble menu' do
    it 'shows a code block bubble menu for a code block' do
      find(content_editor_testid).send_keys '```js ' # trigger input rule
      find(content_editor_testid).send_keys 'var a = 0'
      find(content_editor_testid).send_keys [:shift, :left]

      expect(page).not_to have_css('[data-testid="formatting-bubble-menu"]')
      expect(page).to have_css('[data-testid="code-block-bubble-menu"]')
    end

    it 'sets code block type to "javascript" for `js`' do
      find(content_editor_testid).send_keys '```js '
      find(content_editor_testid).send_keys 'var a = 0'

      expect(find('[data-testid="code-block-bubble-menu"]')).to have_text('Javascript')
    end

    it 'sets code block type to "Custom (nomnoml)" for `nomnoml`' do
      find(content_editor_testid).send_keys '```nomnoml '
      find(content_editor_testid).send_keys 'test'

      expect(find('[data-testid="code-block-bubble-menu"]')).to have_text('Custom (nomnoml)')
    end
  end
end

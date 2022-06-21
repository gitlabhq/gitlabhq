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

  describe 'code block' do
    before do
      visit(profile_preferences_path)

      find('.syntax-theme').choose('Dark')

      wait_for_requests

      page.go_back
      refresh
    end

    it 'applies theme classes to code blocks' do
      expect(page).not_to have_css('.content-editor-code-block.code.highlight.dark')

      find(content_editor_testid).send_keys [:enter, :enter]
      find(content_editor_testid).send_keys '```js ' # trigger input rule
      find(content_editor_testid).send_keys 'var a = 0'

      expect(page).to have_css('.content-editor-code-block.code.highlight.dark')
    end
  end

  describe 'code block bubble menu' do
    it 'shows a code block bubble menu for a code block' do
      find(content_editor_testid).send_keys [:enter, :enter]

      find(content_editor_testid).send_keys '```js ' # trigger input rule
      find(content_editor_testid).send_keys 'var a = 0'
      find(content_editor_testid).send_keys [:shift, :left]

      expect(page).not_to have_css('[data-testid="formatting-bubble-menu"]')
      expect(page).to have_css('[data-testid="code-block-bubble-menu"]')
    end

    it 'sets code block type to "javascript" for `js`' do
      find(content_editor_testid).send_keys [:enter, :enter]

      find(content_editor_testid).send_keys '```js '
      find(content_editor_testid).send_keys 'var a = 0'

      expect(find('[data-testid="code-block-bubble-menu"]')).to have_text('Javascript')
    end

    it 'sets code block type to "Custom (nomnoml)" for `nomnoml`' do
      find(content_editor_testid).send_keys [:enter, :enter]

      find(content_editor_testid).send_keys '```nomnoml '
      find(content_editor_testid).send_keys 'test'

      expect(find('[data-testid="code-block-bubble-menu"]')).to have_text('Custom (nomnoml)')
    end
  end

  describe 'mermaid diagram' do
    before do
      find(content_editor_testid).send_keys [:enter, :enter]

      find(content_editor_testid).send_keys '```mermaid '
      find(content_editor_testid).send_keys ['graph TD;', :enter, '  JohnDoe12 --> HelloWorld34']
    end

    it 'renders and updates the diagram correctly in a sandboxed iframe' do
      iframe = find(content_editor_testid).find('iframe')
      expect(iframe['src']).to include('/-/sandbox/mermaid')

      within_frame(iframe) do
        expect(find('svg').text).to include('JohnDoe12')
        expect(find('svg').text).to include('HelloWorld34')
      end

      expect(iframe['height'].to_i).to be > 100

      find(content_editor_testid).send_keys [:enter, '  JaneDoe34 --> HelloWorld56']

      within_frame(iframe) do
        page.has_content?('JaneDoe34')

        expect(find('svg').text).to include('JaneDoe34')
        expect(find('svg').text).to include('HelloWorld56')
      end
    end

    it 'toggles the diagram when preview button is clicked' do
      find('[data-testid="preview-diagram"]').click

      expect(find(content_editor_testid)).not_to have_selector('iframe')

      find('[data-testid="preview-diagram"]').click

      iframe = find(content_editor_testid).find('iframe')

      within_frame(iframe) do
        expect(find('svg').text).to include('JohnDoe12')
        expect(find('svg').text).to include('HelloWorld34')
      end
    end
  end
end

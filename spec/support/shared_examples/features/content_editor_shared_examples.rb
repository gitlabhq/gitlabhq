# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'edits content using the content editor' do
  include ContentEditorHelpers

  let(:content_editor_testid) { '[data-testid="content-editor"] [contenteditable].ProseMirror' }

  let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
  let(:modifier_key) { is_mac ? :command : :control }

  it 'saves page content in local storage if the user navigates away' do
    switch_to_content_editor

    expect(page).to have_css(content_editor_testid)

    type_in_content_editor ' Typing text in the content editor'

    wait_until_hidden_field_is_updated /Typing text in the content editor/

    begin
      refresh
    rescue Selenium::WebDriver::Error::UnexpectedAlertOpenError
    end

    expect(page).to have_text('Typing text in the content editor')
  end

  describe 'formatting bubble menu' do
    it 'shows a formatting bubble menu for a regular paragraph and headings' do
      switch_to_content_editor

      expect(page).to have_css(content_editor_testid)

      type_in_content_editor 'Typing text in the content editor'
      type_in_content_editor [:shift, :left]

      expect_formatting_menu_to_be_visible

      type_in_content_editor [:right, :right, :enter, '## Heading']

      expect_formatting_menu_to_be_hidden

      type_in_content_editor [:shift, :left]

      expect_formatting_menu_to_be_visible
    end
  end

  describe 'creating and editing links' do
    before do
      switch_to_content_editor
    end

    context 'when clicking the link icon in the toolbar' do
      it 'shows the link bubble menu' do
        page.find('[data-testid="formatting-toolbar"] [data-testid="link"]').click

        expect(page).to have_css('[data-testid="link-bubble-menu"]')
      end

      context 'if no text is selected' do
        before do
          page.find('[data-testid="formatting-toolbar"] [data-testid="link"]').click
        end

        it 'opens an empty inline modal to create a link' do
          page.within '[data-testid="link-bubble-menu"]' do
            expect(page).to have_field('link-text', with: '')
            expect(page).to have_field('link-href', with: '')
          end
        end

        context 'when the user clicks the apply button' do
          it 'applies the changes to the document' do
            page.within '[data-testid="link-bubble-menu"]' do
              fill_in 'link-text', with: 'Link to GitLab home page'
              fill_in 'link-href', with: 'https://gitlab.com'

              click_button 'Apply'
            end

            page.within content_editor_testid do
              expect(page).to have_css('a[href="https://gitlab.com"]')
              expect(page).to have_text('Link to GitLab home page')
            end
          end
        end

        context 'when the user clicks the cancel button' do
          it 'does not apply the changes to the document' do
            page.within '[data-testid="link-bubble-menu"]' do
              fill_in 'link-text', with: 'Link to GitLab home page'
              fill_in 'link-href', with: 'https://gitlab.com'

              click_button 'Cancel'
            end

            page.within content_editor_testid do
              expect(page).not_to have_css('a')
            end
          end
        end
      end

      context 'if text is selected' do
        before do
          type_in_content_editor 'The quick brown fox jumps over the lazy dog'
          type_in_content_editor [:shift, :left]
          type_in_content_editor [:shift, :left]
          type_in_content_editor [:shift, :left]

          page.find('[data-testid="formatting-toolbar"] [data-testid="link"]').click
        end

        it 'prefills inline modal to create a link' do
          page.within '[data-testid="link-bubble-menu"]' do
            expect(page).to have_field('link-text', with: 'dog')
            expect(page).to have_field('link-href', with: '')
          end
        end

        context 'when the user clicks the apply button' do
          it 'applies the changes to the document' do
            page.within '[data-testid="link-bubble-menu"]' do
              fill_in 'link-text', with: 'new dog'
              fill_in 'link-href', with: 'https://en.wikipedia.org/wiki/Shiba_Inu'

              click_button 'Apply'
            end

            page.within content_editor_testid do
              expect(page).to have_selector('a[href="https://en.wikipedia.org/wiki/Shiba_Inu"]',
                text: 'new dog'
              )
            end
          end
        end
      end
    end

    context 'if cursor is placed on an existing link' do
      before do
        type_in_content_editor 'Link to [GitLab home **page**](https://gitlab.com)'
        type_in_content_editor :left
      end

      it 'prefills inline modal to edit the link' do
        page.within '[data-testid="link-bubble-menu"]' do
          page.find('[data-testid="edit-link"]').click

          expect(page).to have_field('link-text', with: 'GitLab home page')
          expect(page).to have_field('link-href', with: 'https://gitlab.com')
        end
      end

      it 'updates the link attributes if text is not updated' do
        page.within '[data-testid="link-bubble-menu"]' do
          page.find('[data-testid="edit-link"]').click

          fill_in 'link-href', with: 'https://about.gitlab.com'

          click_button 'Apply'
        end

        page.within content_editor_testid do
          expect(page).to have_selector('a[href="https://about.gitlab.com"]')
          expect(page.find('a')).to have_text('GitLab home page')
          expect(page).to have_selector('strong', text: 'page')
        end
      end

      it 'updates the link attributes and text if text is updated' do
        page.within '[data-testid="link-bubble-menu"]' do
          page.find('[data-testid="edit-link"]').click

          fill_in 'link-text', with: 'GitLab about page'
          fill_in 'link-href', with: 'https://about.gitlab.com'

          click_button 'Apply'
        end

        page.within content_editor_testid do
          expect(page).to have_selector('a[href="https://about.gitlab.com"]',
            text: 'GitLab about page'
          )
          expect(page).not_to have_selector('strong')
        end
      end

      it 'does nothing if Cancel is clicked' do
        page.within '[data-testid="link-bubble-menu"]' do
          page.find('[data-testid="edit-link"]').click

          click_button 'Cancel'
        end

        page.within content_editor_testid do
          expect(page).to have_selector('a[href="https://gitlab.com"]',
            text: 'GitLab home page'
          )
          expect(page).to have_selector('strong')
        end
      end

      context 'when the user clicks the unlink button' do
        it 'removes the link' do
          page.within '[data-testid="link-bubble-menu"]' do
            page.find('[data-testid="remove-link"]').click
          end

          page.within content_editor_testid do
            expect(page).not_to have_selector('a')
            expect(page).to have_selector('strong', text: 'page')
          end
        end
      end
    end

    context 'when selection spans more than a link' do
      before do
        type_in_content_editor 'a [b **c**](https://gitlab.com)'

        type_in_content_editor [:shift, :left]
        type_in_content_editor [:shift, :left]
        type_in_content_editor [:shift, :left]
        type_in_content_editor [:shift, :left]
        type_in_content_editor [:shift, :left]

        page.find('[data-testid="formatting-toolbar"] [data-testid="link"]').click
      end

      it 'prefills inline modal with the entire selection' do
        page.within '[data-testid="link-bubble-menu"]' do
          expect(page).to have_field('link-text', with: 'a b c')
          expect(page).to have_field('link-href', with: '')
        end
      end

      it 'expands the link and updates the link attributes if text is not updated' do
        page.within '[data-testid="link-bubble-menu"]' do
          fill_in 'link-href', with: 'https://about.gitlab.com'

          click_button 'Apply'
        end

        page.within content_editor_testid do
          expect(page).to have_selector('a[href="https://about.gitlab.com"]')
          expect(page.find('a')).to have_text('a b c')
          expect(page).to have_selector('strong', text: 'c')
        end
      end

      it 'expands the link, updates the link attributes and text if text is updated' do
        page.within '[data-testid="link-bubble-menu"]' do
          fill_in 'link-text', with: 'new text'
          fill_in 'link-href', with: 'https://about.gitlab.com'

          click_button 'Apply'
        end

        page.within content_editor_testid do
          expect(page).to have_selector('a[href="https://about.gitlab.com"]',
            text: 'new text'
          )
          expect(page).not_to have_selector('strong')
        end
      end
    end
  end

  describe 'selecting text' do
    before do
      switch_to_content_editor

      # delete all text first
      type_in_content_editor [modifier_key, 'a']
      type_in_content_editor :backspace

      type_in_content_editor 'The quick **brown** fox _jumps_ over the lazy dog!'
      type_in_content_editor :enter
      type_in_content_editor '[Link](https://gitlab.com)'
      type_in_content_editor :enter
      type_in_content_editor 'Jackdaws love my ~~big~~ sphinx of quartz!'

      # select all text
      type_in_content_editor [modifier_key, 'a']
    end

    it 'renders selected text in a .content-editor-selection class' do
      page.within content_editor_testid do
        assert_selected 'The quick'
        assert_selected 'brown'
        assert_selected 'fox'
        assert_selected 'jumps'
        assert_selected 'over the lazy dog!'

        assert_selected 'Link'

        assert_selected 'Jackdaws love my'
        assert_selected 'big'
        assert_selected 'sphinx of quartz!'
      end
    end

    def assert_selected(text)
      expect(page).to have_selector('.content-editor-selection', text: text)
    end
  end

  describe 'media elements bubble menu' do
    before do
      switch_to_content_editor

      click_attachment_button
    end

    it 'displays correct media bubble menu for images', :js do
      display_media_bubble_menu '[data-testid="content_editor_editablebox"] img[src]', 'dk.png'

      expect_formatting_menu_to_be_hidden
      expect_media_bubble_menu_to_be_visible
    end

    it 'displays correct media bubble menu for video', :js do
      display_media_bubble_menu '[data-testid="content_editor_editablebox"] video', 'video_sample.mp4'

      expect_formatting_menu_to_be_hidden
      expect_media_bubble_menu_to_be_visible
    end
  end

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

      expect_formatting_menu_to_be_hidden
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

  describe 'mermaid diagram' do
    before do
      switch_to_content_editor

      type_in_content_editor [:enter, :enter]
      type_in_content_editor '```mermaid '
      type_in_content_editor ['graph TD;', :enter, '  JohnDoe12 --> HelloWorld34']
    end

    it 'renders and updates the diagram correctly in a sandboxed iframe' do
      iframe = find(content_editor_testid).find('iframe')
      expect(iframe['src']).to include('/-/sandbox/mermaid')

      within_frame(iframe) do
        expect(find('svg .nodes').text).to include('JohnDoe12')
        expect(find('svg .nodes').text).to include('HelloWorld34')
      end

      expect(iframe['height'].to_i).to be > 100

      find(content_editor_testid).send_keys [:enter, '  JaneDoe34 --> HelloWorld56']

      within_frame(iframe) do
        page.has_content?('JaneDoe34')

        expect(find('svg .nodes').text).to include('JaneDoe34')
        expect(find('svg .nodes').text).to include('HelloWorld56')
      end
    end

    it 'toggles the diagram when preview button is clicked',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/397682' do
      find('[data-testid="preview-diagram"]').click

      expect(find(content_editor_testid)).not_to have_selector('iframe')

      find('[data-testid="preview-diagram"]').click

      iframe = find(content_editor_testid).find('iframe')

      within_frame(iframe) do
        expect(find('svg .nodes').text).to include('JohnDoe12')
        expect(find('svg .nodes').text).to include('HelloWorld34')
      end
    end
  end

  describe 'pasting text' do
    before do
      switch_to_content_editor

      type_in_content_editor "Some **rich** _text_ ~~content~~ [link](https://gitlab.com)"

      type_in_content_editor [modifier_key, 'a']
      type_in_content_editor [modifier_key, 'x']
    end

    it 'pastes text with formatting if ctrl + v is pressed' do
      type_in_content_editor [modifier_key, 'v']

      page.within content_editor_testid do
        expect(page).to have_selector('strong', text: 'rich')
        expect(page).to have_selector('em', text: 'text')
        expect(page).to have_selector('s', text: 'content')
        expect(page).to have_selector('a[href="https://gitlab.com"]', text: 'link')
      end
    end

    it 'pastes raw text without formatting if shift + ctrl + v is pressed' do
      type_in_content_editor [modifier_key, :shift, 'v']

      page.within content_editor_testid do
        expect(page).to have_text('Some rich text content link')

        expect(page).not_to have_selector('strong')
        expect(page).not_to have_selector('em')
        expect(page).not_to have_selector('s')
        expect(page).not_to have_selector('a')
      end
    end

    it 'pastes raw text without formatting, stripping whitespaces, if shift + ctrl + v is pressed' do
      type_in_content_editor "    Some **rich**"
      type_in_content_editor :enter
      type_in_content_editor "    _text_"
      type_in_content_editor :enter
      type_in_content_editor "    ~~content~~"
      type_in_content_editor :enter
      type_in_content_editor "    [link](https://gitlab.com)"

      type_in_content_editor [modifier_key, 'a']
      type_in_content_editor [modifier_key, 'x']
      type_in_content_editor [modifier_key, :shift, 'v']

      page.within content_editor_testid do
        expect(page).to have_text('Some rich text content link')
      end
    end
  end

  describe 'autocomplete suggestions' do
    let(:suggestions_dropdown) { '[data-testid="content-editor-suggestions-dropdown"]' }

    before do
      if defined?(project)
        create(:issue, project: project, title: 'My Cool Linked Issue')
        create(:merge_request, source_project: project, source_branch: 'branch-1', title: 'My Cool Merge Request')
        create(:label, project: project, title: 'My Cool Label')
        create(:milestone, project: project, title: 'My Cool Milestone')

        project.add_maintainer(create(:user, name: 'abc123', username: 'abc123'))
      else # group wikis
        project = create(:project, group: group)

        create(:issue, project: project, title: 'My Cool Linked Issue')
        create(:merge_request, source_project: project, source_branch: 'branch-1', title: 'My Cool Merge Request')
        create(:group_label, group: group, title: 'My Cool Label')
        create(:milestone, group: group, title: 'My Cool Milestone')

        project.add_maintainer(create(:user, name: 'abc123', username: 'abc123'))
      end

      switch_to_content_editor

      type_in_content_editor :enter
    end

    it 'shows suggestions for members with descriptions' do
      type_in_content_editor '@a'

      expect(find(suggestions_dropdown)).to have_text('abc123')
      expect(find(suggestions_dropdown)).to have_text('all')
      expect(find(suggestions_dropdown)).to have_text('Group Members')

      type_in_content_editor 'bc'

      send_keys [:arrow_down, :enter]

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).to have_text('@abc123')
    end

    it 'shows suggestions for merge requests' do
      type_in_content_editor '!'

      expect(find(suggestions_dropdown)).to have_text('My Cool Merge Request')

      send_keys :enter

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).to have_text('!1')
    end

    it 'shows suggestions for issues' do
      type_in_content_editor '#'

      expect(find(suggestions_dropdown)).to have_text('My Cool Linked Issue')

      send_keys :enter

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).to have_text('#1')
    end

    it 'shows suggestions for milestones' do
      type_in_content_editor '%'

      expect(find(suggestions_dropdown)).to have_text('My Cool Milestone')

      send_keys :enter

      expect(page).not_to have_css(suggestions_dropdown)
      expect(page).to have_text('%My Cool Milestone')
    end

    it 'shows suggestions for emojis' do
      type_in_content_editor ':smile'

      expect(find(suggestions_dropdown)).to have_text('🙂 slight_smile')
      expect(find(suggestions_dropdown)).to have_text('😸 smile_cat')

      send_keys :enter

      expect(page).not_to have_css(suggestions_dropdown)

      expect(page).to have_text('🙂')
    end

    it 'doesn\'t show suggestions dropdown if there are no suggestions to show' do
      type_in_content_editor '%'

      expect(find(suggestions_dropdown)).to have_text('My Cool Milestone')

      type_in_content_editor 'x'

      expect(page).not_to have_css(suggestions_dropdown)
    end

    it 'scrolls selected item into view when navigating with keyboard' do
      type_in_content_editor ':'

      expect(find(suggestions_dropdown)).to have_text('hundred points symbol')

      expect(dropdown_scroll_top).to be 0

      send_keys :arrow_up

      expect(dropdown_scroll_top).to be > 100
    end

    def dropdown_scroll_top
      evaluate_script("document.querySelector('#{suggestions_dropdown} .gl-dropdown-inner').scrollTop")
    end
  end
end

RSpec.shared_examples 'inserts diagrams.net diagram using the content editor' do
  include ContentEditorHelpers

  before do
    switch_to_content_editor

    click_attachment_button
  end

  it 'displays correct media bubble menu with edit diagram button' do
    display_media_bubble_menu '[data-testid="content_editor_editablebox"] img[src]', 'diagram.drawio.svg'

    expect_formatting_menu_to_be_hidden
    expect_media_bubble_menu_to_be_visible

    click_edit_diagram_button

    expect_drawio_editor_is_opened
  end
end

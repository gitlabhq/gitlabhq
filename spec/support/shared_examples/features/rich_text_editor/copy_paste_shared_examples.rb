# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - copy/paste' do
  include RichTextEditorHelpers

  let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
  let(:modifier_key) { is_mac ? :command : :control }

  describe 'pasting text', feature_category: :markdown do
    before do
      switch_to_content_editor

      type_in_content_editor [modifier_key, 'a']
      type_in_content_editor :delete

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

    it 'does not show a loading indicator after undo paste' do
      type_in_content_editor [modifier_key, 'v']
      type_in_content_editor [modifier_key, 'z']

      page.within content_editor_testid do
        expect(page).not_to have_css('.gl-dots-loader')
      end
    end

    it 'replaces the entire content when pasting over a select-all selection' do
      type_in_content_editor 'Text to replace'

      type_in_content_editor [modifier_key, 'a']
      type_in_content_editor [modifier_key, 'v']

      page.within content_editor_testid do
        expect(page).to have_selector('strong', text: 'rich')
        expect(page).not_to have_text('Text to replace')
        expect(page).not_to have_css('.gl-dots-loader')
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

    it 'pastes raw markdown with formatting when pasting inside a markdown code block' do
      type_in_content_editor '```md'
      type_in_content_editor :enter
      type_in_content_editor [modifier_key, 'v']

      page.within content_editor_testid do
        expect(page).to have_selector('pre', text: 'Some **rich** _text_ ~~content~~ [link](https://gitlab.com)')
      end
    end

    it 'pastes raw markdown without formatting when pasting inside a plaintext code block' do
      type_in_content_editor '```'
      type_in_content_editor :enter
      type_in_content_editor [modifier_key, 'v']

      page.within content_editor_testid do
        expect(page).to have_selector('pre', text: 'Some rich text content link')
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
        expect(page).not_to have_text('    Some rich', normalize_ws: false)
      end
    end

    it 'does not strip indentation when pasting inside a plaintext code block' do
      type_in_content_editor "  text with indentation"

      type_in_content_editor [modifier_key, 'a']
      type_in_content_editor [modifier_key, 'x']

      type_in_content_editor '```'
      type_in_content_editor :enter
      type_in_content_editor [modifier_key, :shift, 'v']

      page.within content_editor_testid do
        expect(page).to have_text("  text with indentation", normalize_ws: false)
      end
    end
  end

  describe 'pasting into a list item', feature_category: :markdown do
    before do
      switch_to_content_editor

      type_in_content_editor [modifier_key, 'a']
      type_in_content_editor :delete
    end

    it 'inserts text copied from a list item inline at the cursor' do
      type_in_content_editor '* item one'

      type_in_content_editor [:shift, :left, :left, :left]
      expect(page.evaluate_script('window.getSelection().toString()')).to eq('one')
      type_in_content_editor [modifier_key, 'c']

      type_in_content_editor :end
      type_in_content_editor :enter
      type_in_content_editor 'item two'
      type_in_content_editor [modifier_key, 'v']

      wait_until_hidden_field_is_updated(/item two.*one/m)

      switch_to_markdown_editor

      expect(page.find('textarea').value.strip).to eq("* item one\n* item twoone")
    end

    it 'inserts text copied from a paragraph inline at the cursor' do
      type_in_content_editor 'plain one'

      type_in_content_editor [:shift, :left, :left, :left]
      expect(page.evaluate_script('window.getSelection().toString()')).to eq('one')
      type_in_content_editor [modifier_key, 'c']

      type_in_content_editor :end
      type_in_content_editor :enter
      type_in_content_editor '* item one'
      type_in_content_editor :enter
      type_in_content_editor 'item two'
      type_in_content_editor [modifier_key, 'v']

      wait_until_hidden_field_is_updated(/item two.*one/m)

      switch_to_markdown_editor

      expect(page.find('textarea').value.strip).to eq("plain one\n\n* item one\n* item twoone")
    end
  end
end

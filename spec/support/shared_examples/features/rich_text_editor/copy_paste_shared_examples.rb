# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - copy/paste' do
  include RichTextEditorHelpers

  let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
  let(:modifier_key) { is_mac ? :command : :control }

  describe 'pasting text' do
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
end

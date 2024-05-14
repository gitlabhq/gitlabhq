# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - selection' do
  include RichTextEditorHelpers

  let(:is_mac) { page.evaluate_script('navigator.platform').include?('Mac') }
  let(:modifier_key) { is_mac ? :command : :control }

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
end

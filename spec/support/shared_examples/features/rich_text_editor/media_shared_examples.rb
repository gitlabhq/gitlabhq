# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - media' do
  include RichTextEditorHelpers

  describe 'media elements bubble menu' do
    before do
      switch_to_content_editor

      click_attachment_button
    end

    it 'displays correct media bubble menu for images', :js do
      display_media_bubble_menu '[data-testid="content_editor_editablebox"] img[src]', 'dk.png'

      expect_media_bubble_menu_to_be_visible
    end

    it 'displays correct media bubble menu for video', :js do
      display_media_bubble_menu '[data-testid="content_editor_editablebox"] video', 'video_sample.mp4'

      expect_media_bubble_menu_to_be_visible
    end
  end
end

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

  describe 'resizing images' do
    it 'renders correctly with an image as initial content after image is resized' do
      click_attachment_button

      switch_to_content_editor
      display_media_bubble_menu '[data-testid="content_editor_editablebox"] img[src]', 'dk.png'

      within content_editor_testid do
        drag_element(find('[data-testid="image-resize-se"]'), -200, -200)
      end

      wait_until_hidden_field_is_updated(/width=/)
      switch_to_markdown_editor

      textarea_value = page.find('textarea').value

      expect(textarea_value).to start_with('![dk.png](/uploads/')
      expect(textarea_value).to end_with('/dk.png){width=260 height=182}')
    end
  end
end

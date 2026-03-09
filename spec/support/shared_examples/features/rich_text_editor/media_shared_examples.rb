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
      display_media_bubble_menu '[data-testid="content_editor_editablebox"] img[src]', 'big-image.png'

      expect_media_bubble_menu_to_be_visible
    end

    it 'displays correct media bubble menu for video', :js do
      display_media_bubble_menu '[data-testid="content_editor_editablebox"] video', 'video_sample.mp4'

      expect_media_bubble_menu_to_be_visible
    end
  end

  describe 'resizing images' do
    it 'renders correctly with an image as initial content after image is resized' do
      page.driver.browser.manage.window.resize_to(1280, 720)
      click_attachment_button

      switch_to_content_editor
      display_media_bubble_menu '[data-testid="content_editor_editablebox"] img[src]', 'big-image.png'

      within content_editor_testid do
        drag_element(find('[data-testid="image-resize-se"]'), -200, -200)
      end

      wait_until_hidden_field_is_updated(/width=/)
      switch_to_markdown_editor

      textarea_value = page.find('textarea').value

      expect(textarea_value).to start_with('![big-image.png](/uploads/')

      # Actual image resolution is 6000x4000 and it gets resized to 700x466 on upload
      expect(textarea_value).to end_with('/big-image.png){width=700 height=466}')
    end
  end
end

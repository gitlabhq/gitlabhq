# frozen_string_literal: true

module RichTextEditorHelpers
  def content_editor_testid
    '[data-testid="content-editor"] [contenteditable].ProseMirror'
  end

  def switch_to_markdown_editor
    click_button("Switch to plain text editing")
  end

  def switch_to_content_editor
    click_button("Switch to rich text editing")

    # wait for the editor to be focused
    find("#{content_editor_testid}:focus")
  end

  def type_in_content_editor(keys)
    find(content_editor_testid).send_keys keys
  end

  def click_attachment_button
    page.find('svg[data-testid="paperclip-icon"]').click
  end

  def set_source_editor_content(content)
    find('.js-gfm-input').set content
  end

  def expect_media_bubble_menu_to_be_visible
    expect(page).to have_css('[data-testid="media-bubble-menu"]')
  end

  def upload_asset(fixture_name)
    attach_file('content_editor_image', Rails.root.join('spec', 'fixtures', fixture_name), make_visible: true)
  end

  def wait_until_hidden_field_is_updated(value)
    expect(page).to have_field(with: value, type: 'hidden')
  end

  def display_media_bubble_menu(media_element_selector, fixture_file)
    upload_asset fixture_file

    wait_for_requests

    expect(page).to have_css(media_element_selector)

    page.find(media_element_selector).click
  end

  def click_edit_diagram_button
    page.find('[data-testid="edit-diagram"]').click
  end

  def expect_drawio_editor_is_opened
    expect(page).to have_css('#drawio-frame', visible: :hidden)
  end

  def drag_element(element, dx, dy)
    page.execute_script(<<-JS, element, dx, dy)
      function simulateDragDrop(element, dx, dy) {
        const rect = element.getBoundingClientRect();
        const events = ['mousedown', 'mousemove', 'mouseup'];
        events.forEach((eventType, index) => {
          const event = new MouseEvent(eventType, {
            bubbles: true,
            screenX: rect.left + (index ? dx : 0),
            screenY: rect.top + (index ? dy : 0)
          });
          element.dispatchEvent(event);
        });
      }
      simulateDragDrop(arguments[0], arguments[1], arguments[2]);
    JS
  end
end

# frozen_string_literal: true

module ContentEditorHelpers
  def switch_to_content_editor
    click_button("Switch to rich text")
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
end

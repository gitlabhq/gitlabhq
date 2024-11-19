# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'rich text editor - diagrams' do
  include RichTextEditorHelpers

  describe 'mermaid diagram' do
    before do
      switch_to_content_editor

      type_in_content_editor [:enter, :enter]
      type_in_content_editor '```mermaid '
      type_in_content_editor ['graph TD;', :enter, '  JohnDoe12 --> HelloWorld34']
    end

    it 'renders and updates the diagram correctly in a sandboxed iframe',
      quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/480101' do
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

  describe 'drawio diagram' do
    before do
      switch_to_content_editor

      click_attachment_button
    end

    it 'displays correct media bubble menu with edit diagram button' do
      display_media_bubble_menu '[data-testid="content_editor_editablebox"] img[src]', 'diagram.drawio.svg'

      expect_media_bubble_menu_to_be_visible

      click_edit_diagram_button

      expect_drawio_editor_is_opened
    end
  end
end

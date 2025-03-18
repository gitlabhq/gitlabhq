# frozen_string_literal: true

module Features
  # These helpers help you interact within the blobs page and blobs edit page (Single file editor).
  module BlobSpecHelpers
    include ActionView::Helpers::JavaScriptHelper

    def edit_in_single_file_editor
      click_button 'Edit'
      click_link_or_button 'Edit single file'
    end

    def edit_in_web_ide
      # rubocop:disable Gitlab/FeatureFlagWithoutActor -- omit actor param in tests
      if Feature.enabled?(:directory_code_dropdown_updates)
        # rubocop:enable Gitlab/FeatureFlagWithoutActor -- omit actor param in tests
        within_testid('code-dropdown') do
          click_button 'Code'
        end
      else
        click_button 'Edit'
      end

      click_link_or_button 'Web IDE'
    end
  end
end

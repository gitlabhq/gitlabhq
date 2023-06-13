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
      click_button 'Edit'
      click_link_or_button 'Web IDE'
    end
  end
end

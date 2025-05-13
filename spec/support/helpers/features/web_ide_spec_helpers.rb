# frozen_string_literal: true

# These helpers help you interact within the Web IDE.
#
# Usage:
#   describe "..." do
#     include Features::WebIdeSpecHelpers
#     ...
#
#     ide_visit(project)
#     ide_commit
module Features
  module WebIdeSpecHelpers
    include Features::SourceEditorSpecHelpers
    include Features::BlobSpecHelpers

    # Open the IDE from anywhere by first visiting the given project's page
    def ide_visit(project)
      visit project_path(project)

      ide_visit_from_link
    end

    # Open the IDE from the current page by clicking the Web IDE link
    def ide_visit_from_link
      new_tab = window_opened_by do
        edit_in_web_ide
      end

      switch_to_window new_tab
    end

    def within_web_ide(&block)
      iframe = find('#ide iframe')
      page.within_frame(iframe, &block)
    end
  end
end

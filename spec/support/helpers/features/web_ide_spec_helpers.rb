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

    def ide_tree_body
      page.find('.ide-tree-body')
    end

    def ide_tree_actions
      page.find('.ide-tree-actions')
    end

    def ide_tab_selector(mode)
      ".js-ide-#{mode}-mode"
    end

    def ide_folder_row_open?(row)
      row.matches_css?('.folder.is-open')
    end

    # Deletes a file by traversing to `path`
    # then clicking the 'Delete' action.
    #
    # - Throws an error if the file is not found
    def ide_delete_file(path)
      container = ide_traverse_to_file(path)

      click_file_action(container, 'Delete')
    end

    # Opens parent directories until the file at `path`
    # is exposed.
    #
    # - Returns a reference to the file row at `path`
    # - Throws an error if the file is not found
    def ide_traverse_to_file(path)
      paths = path.split('/')
      container = nil

      paths.each_with_index do |path, index|
        ide_open_file_row(container) if container
        container = find_file_child(container, path, level: index)
      end

      container
    end

    def ide_open_file_row(row)
      return if ide_folder_row_open?(row)

      row.click
    end

    def ide_set_editor_value(value)
      editor_set_value(value)
    end

    def ide_commit_tab_selector
      ide_tab_selector('commit')
    end

    def ide_commit
      find(ide_commit_tab_selector).click

      commit_to_current_branch
    end

    private

    def file_row_container(row)
      row ? row.find(:xpath, '..') : ide_tree_body
    end

    def find_file_child(row, name, level: nil)
      container = file_row_container(row)
      container.find(".file-row[data-level=\"#{level}\"]", text: name)
    end

    def click_file_action(row, text)
      row.hover
      dropdown = row.find('.ide-new-btn')
      dropdown.find('button').click
      dropdown.find('button', text: text).click
    end

    def commit_to_current_branch(option: 'Commit to master branch', message: '')
      within '.multi-file-commit-form' do
        fill_in('commit-message', with: message) if message

        choose(option)

        click_button('Commit')

        wait_for_requests
      end
    end
  end
end

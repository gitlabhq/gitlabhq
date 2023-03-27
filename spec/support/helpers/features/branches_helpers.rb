# frozen_string_literal: true

# These helpers allow you to manipulate with sorting features.
#
# Usage:
#   describe "..." do
#     include Features::BranchesHelpers
#     ...
#
#     create_branch("feature")
#     select_branch("master")
#
module Features
  module BranchesHelpers
    include ListboxHelpers

    def create_branch(branch_name, source_branch_name = "master")
      fill_in("branch_name", with: branch_name)
      select_branch(source_branch_name)
      click_button("Create branch")
    end

    def select_branch(branch_name)
      wait_for_requests

      click_button branch_name
      send_keys branch_name
      select_listbox_item(branch_name)
    end
  end
end

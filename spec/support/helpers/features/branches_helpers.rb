# frozen_string_literal: true

# These helpers allow you to manipulate with sorting features.
#
# Usage:
#   describe "..." do
#     include Spec::Support::Helpers::Features::BranchesHelpers
#     ...
#
#     create_branch("feature")
#     select_branch("master")
#
module Spec
  module Support
    module Helpers
      module Features
        module BranchesHelpers
          def create_branch(branch_name, source_branch_name = "master")
            fill_in("branch_name", with: branch_name)
            select_branch(source_branch_name)
            click_button("Create branch")
          end

          def select_branch(branch_name)
            ref_selector = '.ref-selector'
            find(ref_selector).click
            wait_for_requests

            page.within(ref_selector) do
              fill_in _('Search by Git revision'), with: branch_name
              wait_for_requests
              find('li', text: branch_name, match: :prefer_exact).click
            end
          end
        end
      end
    end
  end
end

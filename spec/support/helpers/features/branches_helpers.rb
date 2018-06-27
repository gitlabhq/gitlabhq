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
            find(".git-revision-dropdown-toggle").click

            page.within("#new-branch-form .dropdown-menu") do
              click_link(branch_name)
            end
          end
        end
      end
    end
  end
end

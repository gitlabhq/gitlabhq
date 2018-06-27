# These helpers allow you to manipulate with sorting features.
#
# Usage:
#   describe "..." do
#     include Spec::Support::Helpers::Features::SortingHelpers
#     ...
#
#     sort_by("Last updated")
#
module Spec
  module Support
    module Helpers
      module Features
        module SortingHelpers
          def sort_by(value)
            find('button.dropdown-toggle').click

            page.within('.content ul.dropdown-menu.dropdown-menu-right li') do
              click_link(value)
            end
          end
        end
      end
    end
  end
end

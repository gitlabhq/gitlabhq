# frozen_string_literal: true

# These helpers allow you to manipulate with sorting features.
#
# Usage:
#   describe "..." do
#     include Features::SortingHelpers
#     ...
#
#     sort_by("Last updated")
#
module Features
  module SortingHelpers
    def sort_by(value)
      find('.filter-dropdown-container .dropdown').click

      page.within('ul.dropdown-menu.dropdown-menu-right li') do
        click_link(value)
      end
    end

    # pajamas_sort_by is used to sort new pajamas dropdowns. When
    # all of the dropdowns are converted, pajamas_sort_by can be renamed to sort_by
    # https://gitlab.com/groups/gitlab-org/-/epics/7551
    def pajamas_sort_by(value, from: nil)
      raise ArgumentError, 'The :from option must be given' if from.nil?

      click_button from
      find('[role="option"]', text: value).click
    end
  end
end

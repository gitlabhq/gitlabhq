# Helper allows you to sort items
#
# Params
#   value - value for sorting
#
# Usage:
#   include SortingHelper
#
#   sorting_by('Oldest updated')
#
module SortingHelper
  def sorting_by(value)
    find('button.dropdown-toggle').click
    page.within('.content ul.dropdown-menu.dropdown-menu-align-right li') do
      click_link value
    end
  end
end

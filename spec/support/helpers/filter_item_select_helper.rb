# Helper allows you to select value from filter-items
#
# Params
#   value - value for select
#   selector - css selector of item
#
# Usage:
#
#   filter_item_select('Any Author', '.js-author-search')
#
module FilterItemSelectHelper
  def filter_item_select(value, selector)
    find(selector).click
    wait_for_requests
    page.within('.dropdown-content') do
      click_link value
    end
  end
end

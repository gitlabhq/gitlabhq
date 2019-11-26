# frozen_string_literal: true

module SearchHelpers
  def submit_search(query, scope: nil)
    page.within('.search-form, .search-page-form') do
      field = find_field('search')
      field.fill_in(with: query)

      if javascript_test?
        field.send_keys(:enter)
      else
        click_button('Search')
      end
    end
  end

  def select_search_scope(scope)
    page.within '.search-filter' do
      click_link scope
    end
  end

  def has_search_scope?(scope)
    page.within '.search-filter' do
      has_link?(scope)
    end
  end

  def max_limited_count
    Gitlab::SearchResults::COUNT_LIMIT_MESSAGE
  end
end

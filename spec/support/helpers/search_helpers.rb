# frozen_string_literal: true

module SearchHelpers
  def fill_in_search(text)
    page.within('.header-search-new') do
      find('#search').click
      fill_in 'search', with: text
    end

    wait_for_all_requests
  end

  def submit_search(query)
    page.within('.header-search, .search-page-form') do
      field = find_field('search')
      field.click
      field.fill_in(with: query)

      if javascript_test?
        field.send_keys(:enter)
      else
        click_button('Search')
      end

      wait_for_all_requests
    end
  end

  def select_search_scope(scope)
    page.within '[data-testid="search-filter"]' do
      click_link scope

      wait_for_all_requests
    end
  end

  def has_search_scope?(scope)
    page.within '[data-testid="search-filter"]' do
      has_link?(scope)
    end
  end

  def max_limited_count
    Gitlab::SearchResults::COUNT_LIMIT_MESSAGE
  end
end

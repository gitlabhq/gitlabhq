# frozen_string_literal: true

module SearchHelpers
  def fill_in_search(text)
    within_testid('super-sidebar') do
      click_button "Search or go to…"
    end
    fill_in 'search', with: text

    wait_for_all_requests
  end

  def submit_search(query)
    # Forms directly on the search page
    if page.has_css?('.search-page-form')
      search_form = '.search-page-form'
    # Open search modal from super sidebar
    else
      find_by_testid('super-sidebar-search-button').click
      search_form = '#super-sidebar-search-modal'
    end

    page.within(search_form) do
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
    within_testid('search-filter') do
      click_link scope

      wait_for_all_requests
    end
  end

  def has_search_scope?(scope)
    return false unless has_testid?('search-filter')

    within_testid('search-filter') do
      has_link?(scope)
    end
  end

  def max_limited_count
    Gitlab::SearchResults::COUNT_LIMIT_MESSAGE
  end
end

# frozen_string_literal: true

module GlFilteredSearchHelpers # rubocop:disable Search/NamespacedClass -- false positive
  def gl_filtered_search_input(scope = page)
    scope.find('[data-testid="filtered-search-input"] input')
  end

  def gl_filtered_search_dropdown(scope = page)
    scope.find('.gl-filtered-search-suggestion-list')
  end

  def gl_filtered_search_first_suggestion(scope = page)
    gl_filtered_search_dropdown(scope).first('.gl-filtered-search-suggestion')
  end

  def gl_filtered_search_set_input(term, scope: page, submit: false)
    input = gl_filtered_search_input(scope)
    input.click
    input.set(term)

    return unless submit

    scope.click_button 'Search'
    wait_for_requests
  end
end

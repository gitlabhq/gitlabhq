module FilteredSearchHelpers
  def filtered_search
    page.find('.filtered-search')
  end

  def input_filtered_search(search_term, submit: true)
    filtered_search.set(search_term)

    if submit
      filtered_search.send_keys(:enter)
    end
  end

  def input_filtered_search_keys(search_term)
    filtered_search.send_keys(search_term)
    filtered_search.send_keys(:enter)
  end

  def expect_filtered_search_input(input)
    expect(find('.filtered-search').value).to eq(input)
  end

  def clear_search_field
    find('.filtered-search-input-container .clear-search').click
  end

  def reset_filters
    clear_search_field
    filtered_search.send_keys(:enter)
  end

  def init_label_search
    filtered_search.set('label:')
    # This ensures the dropdown is shown
    expect(find('#js-dropdown-label')).not_to have_css('.filter-dropdown-loading')
  end
end
